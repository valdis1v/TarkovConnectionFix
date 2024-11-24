function Get-OptimalMTU {
    $tarkovhost = "prod.escapefromtarkov.com"
    $maxMTU = 1500
    $minMTU = 1400
    $optimalMTU = $maxMTU

    Write-Host "Ermittle optimale MTU für $tarkovhost..."

    while ($maxMTU -ge $minMTU) {
        $testMTU = [math]::Floor(($maxMTU + $minMTU) / 2)

        $pingResult = & ping $tarkovhost -f -l $testMTU 2>&1

        if ($pingResult -match "100% Verlust") {
            $maxMTU = $testMTU - 1
        }
        elseif ($pingResult -match "75% Verlust") {
            $maxMTU = $testMTU - 1
        }
        elseif ($pingResult -match "50% Verlust") {
            $maxMTU = $testMTU - 1
        }
        elseif ($pingResult -match "25% Verlust") {
            $maxMTU = $testMTU - 1
        }
        else {
            $minMTU = $testMTU + 1
        }

        if ($maxMTU - $minMTU -lt 1) {
            break
        }
    }

    $optimalMTU = $maxMTU
    Write-Host "Optimale MTU gefunden: $optimalMTU"
    return $optimalMTU + 28
}

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
#main, needs restart after execution
$optimalMTU = Get-OptimalMTU
Set-MTU -MTUValue $optimalMTU
Write-Host "Konfiguration abgeschlossen. Bitte starte deinen PC neu!"