param([string] $resourceName) 
					$token = (Get-AzAccessToken -ResourceUrl https://graph.microsoft.com).Token
      				$headers = @{'Content-Type' = 'application/json'; 'Authorization' = 'Bearer ' + $token}

      				$template = @{
        				displayName = $resourceName
        				requiredResourceAccess = @(
          					@{
            					resourceAppId = "00000004-0000-0000-c000-000000000000"
            					resourceAccess = @(
              						@{
                						id = "dfb62f81-fb9f-43aa-b3ef-2f2e0105ca0e"
                						type = "Scope"
              						}
            					)
          					}
        				)
        				signInAudience = "AzureADMyOrg"
      				}
      
      				// Upsert App registration
      				$app = (Invoke-RestMethod -Method Get -Headers $headers -Uri "https://graph.microsoft.com/beta/applications?$filter=displayName eq '$($resourceName)'").value
      				$principal = @{}
      				if ($app) {
        				$ignore = Invoke-RestMethod -Method Patch -Headers $headers -Uri "https://graph.microsoft.com/beta/applications/$($app.id)" -Body ($template | ConvertTo-Json -Depth 10)
        				$principal = (Invoke-RestMethod -Method Get -Headers $headers -Uri "https://graph.microsoft.com/beta/servicePrincipals?filter=appId eq '$($app.appId)'").value
      				} else {
        				$app = (Invoke-RestMethod -Method Post -Headers $headers -Uri "https://graph.microsoft.com/beta/applications" -Body ($template | ConvertTo-Json -Depth 10))
        				$principal = Invoke-RestMethod -Method POST -Headers $headers -Uri  "https://graph.microsoft.com/beta/servicePrincipals" -Body (@{ "appId" = $app.appId } | ConvertTo-Json)
      				}
      
      				// Creating client secret
      				$app = (Invoke-RestMethod -Method Get -Headers $headers -Uri "https://graph.microsoft.com/beta/applications/$($app.id)")
      
      				foreach ($password in $app.passwordCredentials) {
        				Write-Host "Deleting secret with id: $($password.keyId)"
        				$body = @{
          					"keyId" = $password.keyId
        				}
						$ignore = Invoke-RestMethod -Method POST -Headers $headers -Uri "https://graph.microsoft.com/beta/applications/$($app.id)/removePassword" -Body ($body | ConvertTo-Json)
      				}
      
      				$body = @{
        				"passwordCredential" = @{
          				"displayName"= "Client Secret"
        			}
      			}
      			$secret = (Invoke-RestMethod -Method POST -Headers $headers -Uri  "https://graph.microsoft.com/beta/applications/$($app.id)/addPassword" -Body ($body | ConvertTo-Json)).secretText
      
      			$DeploymentScriptOutputs = @{}
      			$DeploymentScriptOutputs['objectId'] = $app.id
      			$DeploymentScriptOutputs['clientId'] = $app.appId
      			$DeploymentScriptOutputs['clientSecret'] = $secret
      			$DeploymentScriptOutputs['principalId'] = $principal.id