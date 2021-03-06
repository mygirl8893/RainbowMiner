﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [Bool]$InfoOnly
)

$Path = ".\Bin\CryptoNight-Cast\cast_xmr-vega.exe"
$Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.50-cast/cast_xmr-vega-win64_150.zip"
$Port = "306{0:d2}"
$DevFee = 1.5

if (-not $Session.DevicesByTypes.AMD -and -not $InfoOnly) {return} # No AMD present in system

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{MainAlgorithm = "cryptonightfast"; Params = "--algo=8 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightfest"; Params = "--algo=9 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightheavy"; Params = "--algo=2 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightlite"; Params = "--algo=3 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonighttubeheavy"; Params = "--algo=5 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightv7"; Params = "--algo=1 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightv7lite"; Params = "--algo=4 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightv7stellitev4"; Params = "--algo=6 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightv8"; Params = "--algo=10 --intensity=8"}
    [PSCustomObject]@{MainAlgorithm = "cryptonightxhvheavy"; Params = "--algo=7 --intensity=8"}
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

if ($InfoOnly) {
    [PSCustomObject]@{
        Type      = @("AMD")
        Name      = $Name
        Path      = $Path
        Port      = $Miner_Port
        Uri       = $Uri
        DevFee    = $DevFee
        ManualUri = $ManualUri
        Commands  = $Commands
    }
    return
}

$Session.DevicesByTypes.AMD | Select-Object Vendor, Model -Unique | ForEach-Object {
    $Miner_Device = $Session.Devices | Where-Object Vendor -EQ $_.Vendor | Where-Object Model -EQ $_.Model
    $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
    $Miner_Model = $_.Model
    $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
    $Miner_Port = Get-MinerPort -MinerName $Name -DeviceName @($Miner_Device.Name) -Port $Miner_Port

    $DeviceIDsAll = $Miner_Device.Type_Vendor_Index -join ','

    $Commands | ForEach-Object {

        $Algorithm_Norm = Get-Algorithm $_.MainAlgorithm

        if ($Pools.$Algorithm_Norm.Host -and $Miner_Device) {
            [PSCustomObject]@{
                Name = $Miner_Name
                DeviceName = $Miner_Device.Name
                DeviceModel = $Miner_Model
                Path      = $Path
                Arguments = "--remoteaccess --remoteport $($Miner_Port) -S $($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass) --forcecompute --fastjobswitch -G $($DeviceIDsAll) $($_.Params)" 
                HashRates = [PSCustomObject]@{$Algorithm_Norm = $Session.Stats."$($Miner_Name)_$($Algorithm_Norm)_HashRate".Week}
                API       = "Cast"
                Port      = $Miner_Port
                URI       = $Uri
                DevFee    = $DevFee
                ManualUri = $ManualUri
            }
        }
    }
}