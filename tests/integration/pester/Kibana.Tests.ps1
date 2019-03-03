Describe 'The kibana application' {
    Context 'is installed' {
        It 'with files in /usr/share/kibana' {
            '/usr/share/kibana' | Should Exist
            '/usr/share/kibana/bin' | Should Exist
            '/usr/share/kibana/bin/kibana' | Should Exist
        }

        It 'with default configuration in /etc/kibana' {
            '/etc/kibana/kibana.yml' | Should Exist
        }
    }

    Context 'has been daemonized' {
        $serviceConfigurationPath = '/etc/systemd/system/kibana.service'
        if (-not (Test-Path $serviceConfigurationPath)) {
            It 'has a systemd configuration' {
                $false | Should Be $true
            }
        }

        $expectedContent = @'
[Unit]
Description=Kibana
StartLimitIntervalSec=30
StartLimitBurst=3

[Service]
Type=simple
User=kibana
Group=kibana
# Load env vars from /etc/default/ and /etc/sysconfig/ if they exist.
# Prefixing the path with '-' makes it try to load, but if the file doesn't
# exist, it continues onward.
EnvironmentFile=-/etc/default/kibana
EnvironmentFile=-/etc/sysconfig/kibana
ExecStart=/usr/share/kibana/bin/kibana "-c /etc/kibana/kibana.yml"
Restart=always
WorkingDirectory=/

[Install]
WantedBy=multi-user.target

'@
        $serviceFileContent = Get-Content $serviceConfigurationPath | Out-String
        $systemctlOutput = & systemctl status kibana
        It 'with a systemd service' {
            $serviceFileContent | Should Be ($expectedContent -replace "`r", "")

            $systemctlOutput | Should Not Be $null
            $systemctlOutput.GetType().FullName | Should Be 'System.Object[]'
            $systemctlOutput.Length | Should BeGreaterThan 3
            $systemctlOutput[0] | Should Match 'kibana.service - Kibana'
        }

        It 'that is enabled' {
            $systemctlOutput[1] | Should Match 'Loaded:\sloaded\s\(.*;\senabled;.*\)'

        }

        It 'and is running' {
            $systemctlOutput[2] | Should Match 'Active:\sactive\s\(running\).*'
        }
    }

    Context 'can be contacted' {
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:5601/api/status" -Headers $headers -UseBasicParsing
        }
        catch {
            # Because powershell sucks it throws if the response code isn't a 200 one ...
            $response = $_.Exception.Response
        }

        It 'responds to HTTP calls' {
            $response.StatusCode | Should Be 200
        }
    }
}
