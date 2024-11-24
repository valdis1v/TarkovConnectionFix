# MTU-Autokonfiguration für Windows-Netzwerkadapter

# Funktion: MTU-Wert durch Pings ermitteln
function Get-OptimalMTU {
    $tarkovhost = "prod.escapefromtarkov.com"
    $maxMTU = 1500
    $minMTU = 1400
    $optimalMTU = $maxMTU

    Write-Host "Ermittle optimale MTU für $tarkovhost..."

    while ($minMTU -le $maxMTU) {
        $testMTU = [math]::Floor(($minMTU + $maxMTU) / 2)
        $pingResult = Test-Connection -ComputerName $tarkovhost -BufferSize $testMTU -Count 1 -DontFragment -ErrorAction SilentlyContinue

        if ($pingResult) {
            $optimalMTU = $testMTU
            $minMTU = $testMTU + 1
        } else {
            $maxMTU = $testMTU - 1
        }
    }

    Write-Host "Optimale MTU ermittelt: $optimalMTU"
    return $optimalMTU + 28
}

# Funktion: MTU auf allen Adaptern setzen
function Set-MTU {
    param (
        [int]$MTUValue
    )

    $adapters = Get-NetIPInterface | Where-Object {$_.InterfaceOperationalStatus -eq "Up"}
    foreach ($adapter in $adapters) {
        Write-Host "Setze MTU=$MTUValue für Adapter: $($adapter.InterfaceAlias)"
        Start-Process -FilePath "netsh" -ArgumentList "int ipv4 set subinterface `"$($adapter.InterfaceAlias)`" mtu=$MTUValue store=persistent" -NoNewWindow -Wait
    }
}

# Main
$optimalMTU = Get-OptimalMTU
Set-MTU -MTUValue $optimalMTU
Write-Host "Konfiguration abgeschlossen. Neustart empfohlen!"
