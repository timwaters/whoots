<?php
declare(strict_types=1);

class WhootsApp {
    public static function call(array $serverVars): array|bool {
        $path = $serverVars['REQUEST_URI'] ?? '';
        $path = parse_url($path, PHP_URL_PATH);
        
        // Serve index.html for root path
        if ($path === '/') {
            return [
                'status' => 200,
                'headers' => ['Content-Type' => 'text/html'],
                'body' => file_get_contents('public/index.html')
            ];
        }

        // Serve the specific image file
        if ($path === '/images/whoots_tiles.jpg') {
            $filePath = 'public/images/whoots_tiles.jpg';
            if (file_exists($filePath) && is_file($filePath)) {
                $mimeType = mime_content_type($filePath);
                return [
                    'status' => 200,
                    'headers' => ['Content-Type' => $mimeType],
                    'body' => file_get_contents($filePath)
                ];
            }
        }
        
        if (preg_match('/^\/hi\b/', $path)) {
            return [
                'status' => 200,
                'headers' => ['Content-Type' => 'text/plain'],
                'body' => 'Hello World!'
            ];
        }
        
        if (preg_match('#^/tms/(\d+)/(\d+)/(\d+)/([^/]+)/#', $path, $matches)) {
            $params = explode('/', trim($path, '/'));
            
            // Validate numeric parameters
            if (!preg_match('/^\d+$/', $params[1]) || 
                !preg_match('/^\d+$/', $params[2]) || 
                !preg_match('/^\d+$/', $params[3])) {
                return [
                    'status' => 400,
                    'headers' => ['Content-Type' => 'text/plain'],
                    'body' => 'Invalid parameters'
                ];
            }
            
            $layer = preg_replace('/[^a-zA-Z0-9\-_\.:\s%]/', '', $params[4]);
            
            $z = (int)$params[1];
            $x = (int)$params[2];
            $y = (int)$params[3];
            
            // Get the scheme from the path
            $scheme = 'http';
            if (isset($params[6]) && preg_match('/^https?:$/', $params[6])) {
                $scheme = rtrim($params[6], ':');
            }
            
            // Sanitize and build splat path
            $splatParams = array_slice($params, 6);
            $sanitizedSplat = array_filter($splatParams, fn($p) => preg_match('/^[\w\-\.\/]+$/', $p));
            $splat = $scheme . "://" . implode("/", $sanitizedSplat);
            
            if (empty($splat)) {
                return [
                    'status' => 400,
                    'headers' => ['Content-Type' => 'text/plain'],
                    'body' => 'Invalid path'
                ];
            }
            
            // Parse query parameters
            $queryString = $serverVars['QUERY_STRING'] ?? '';
            parse_str($queryString, $queryParams);
            
            // For Google/OSM tile scheme we need to alter the y
            $y = ((2 ** $z) - $y - 1);
            
            // Calculate bbox
            $bbox = self::getTileBbox($x, $y, $z);
            
            // Build WMS parameters
            $format = ($queryParams['format'] ?? '') === 'image/jpeg' ? 'image/jpeg' : 'image/png';
            $wmsParams = [
                'bbox' => $bbox,
                'format' => $format,
                'service' => 'WMS',
                'version' => '1.1.1',
                'request' => 'GetMap',
                'srs' => 'EPSG:3857',
                'width' => '256',
                'height' => '256',
                'layers' => $layer,
                'styles' => ''
            ];
            
            // Add map parameter if it exists
            if (!empty($queryParams['map'])) {
                $map = preg_replace('/[^a-zA-Z0-9\-_\.\/]/', '', $queryParams['map']);
                $wmsParams['map'] = $map;
            }
            
            $url = $splat . '?' . http_build_query($wmsParams);
            
            return [
                'status' => 302,
                'headers' => ['Location' => $url],
                'body' => ''
            ];
        }
        
        return [
            'status' => 404,
            'headers' => ['Content-Type' => 'text/html'],
            'body' => '<html>Not found. <a href="/">Whoots</a></html>'
        ];
    }
    
    private static function getTileBbox(int $x, int $y, int $z): string {
        [$minX, $minY] = self::getMercCoords($x * 256, $y * 256, $z);
        [$maxX, $maxY] = self::getMercCoords(($x + 1) * 256, ($y + 1) * 256, $z);
        return "{$minX},{$minY},{$maxX},{$maxY}";
    }
    
    private static function getMercCoords(int $x, int $y, int $z): array {
        $resolution = (2 * M_PI * 6378137 / 256) / (2 ** $z);
        $mercX = ($x * $resolution - 2 * M_PI * 6378137 / 2.0);
        $mercY = ($y * $resolution - 2 * M_PI * 6378137 / 2.0);
        return [$mercX, $mercY];
    }
}

// Example usage in a front controller:
if (php_sapi_name() !== 'cli') {
    $result = WhootsApp::call($_SERVER);
    http_response_code($result['status']);
    foreach ($result['headers'] as $name => $value) {
        header("$name: $value");
    }
    echo $result['body'];
}
?> 