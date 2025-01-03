# Script d'Audit Système Windows Server
# Objectif : Automatiser les vérifications systèmes et journaux

# 1. Définir les paramètres du script
$RapportPath = "C:\Audit_Serveur"
$RapportFile = "$RapportPath\Rapport_Audit_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').txt"

# Créer le dossier de rapport si non existant
If (!(Test-Path -Path $RapportPath)) {
    New-Item -ItemType Directory -Path $RapportPath
}

# 2. Surveillance des Ressources Systèmes
Add-Content -Path $RapportFile -Value "=== Surveillance des Ressources ==="
Add-Content -Path $RapportFile -Value "Date: $(Get-Date)"

# CPU et RAM
#$CPU = Get-Counter '\Processor(_Total)\% Processor Time'
#$RAM = Get-Counter '\Memory\% Committed Bytes In Use'
#Add-Content -Path $RapportFile -Value "CPU Utilisation: $($CPU.CounterSamples.CookedValue)%"
#Add-Content -Path $RapportFile -Value "RAM Utilisation: $($RAM.CounterSamples.CookedValue)%"
#RAM

Add-Content -Path $RapportFile -Value "`n=== RAM ==="
$gpuLocalUsage = (Get-Counter '\GPU Local Adapter Memory(*)\Local Usage').CounterSamples
$gpuLocalUsage | ForEach-Object {
    $valueInGB = [math]::Round($_.CookedValue / 1GB, 2)
    #Write-Output ("Instance: {0}, Value: {1} GB" -f $_.InstanceName, $valueInGB)
    Add-Content -Path $RapportFile -Value "$($_.InstanceName, $valueInGB) Go"
}

# Espace Disque"
Add-Content -Path $RapportFile -Value "`n=== Espace Disque ==="
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $freeSpaceGB = [math]::Round($_.Free / 1GB, 2)
    $totalSpaceGB = [math]::Round(($_.Used + $_.Free) / 1GB, 2)
    
    Add-Content -Path $RapportFile -Value "$($_.Name): $freeSpaceGB Go libres sur $totalSpaceGB Go"
}

# 3. Vérification des Services Critiques
Add-Content -Path $RapportFile -Value "`n=== Services Critiques ==="
$servicesCritiques = @("DNS", "DHCP", "W32Time", "TermService") # Ajoutez vos services ici
foreach ($service in $servicesCritiques) {
    $etat = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($etat.Status -eq "Running") {
        Add-Content -Path $RapportFile -Value "$service : En cours d'exécution OK"
    } else {
        Add-Content -Path $RapportFile -Value "$service : Arrêté KO"
    }
}

# 4. Analyse des Journaux d'Événements
Add-Content -Path $RapportFile -Value "`n=== Analyse des Journaux d'Événements ==="
$Logs = Get-WinEvent -LogName System -MaxEvents 50 | Where-Object { $_.LevelDisplayName -eq "Error" }

if ($Logs) {
    Add-Content -Path $RapportFile -Value "Erreurs détectées :"
    foreach ($log in $Logs) {
        Add-Content -Path $RapportFile -Value "[$($log.TimeCreated)] $($log.ProviderName) - $($log.Message)"
    }
} else {
    Add-Content -Path $RapportFile -Value "Aucune erreur détectée dans les derniers 50 événements. OK"
}

# 5. Vérification de l'Intégrité du Système
Add-Content -Path $RapportFile -Value "`n=== Intégrité du Système ==="
$sfcResult = sfc /scannow | Out-String
Add-Content -Path $RapportFile -Value "$sfcResult"

# 6. Rapport Final
Add-Content -Path $RapportFile -Value "`n=== Audit Terminé ==="
Add-Content -Path $RapportFile -Value "Rapport généré avec succès : $RapportFile"

# 7. Ouvrir le Rapport
Invoke-Item $RapportFile
