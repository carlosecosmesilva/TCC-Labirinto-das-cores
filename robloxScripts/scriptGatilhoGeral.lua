local gatilho = script.Parent
local debounce = false

-- CONFIGURAÇÃO DA PORTA (Mude o valor abaixo para cada porta)
-- Opções: "Normal", "Daltonico", "Erro", "Protan", "Deutan"
local tipoDePorta = "Normal" 

-- Nome da próxima sala para teleporte (Certifique-se que o objeto existe no Workspace)
local nomeProximaSala = "Sala_02" 

gatilho.Touched:Connect(function(hit)
	local personagem = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(personagem)

	if player and not debounce then
		debounce = true
		local pasta = player:WaitForChild("ResultadosDaltonismo")

		-- LÓGICA DE PONTUAÇÃO BASEADA NO TIPO
		if tipoDePorta == "Normal" then
			pasta.Normal.Value += 1
		elseif tipoDePorta == "Daltonico" then
			pasta.Deficiente.Value += 1
		elseif tipoDePorta == "Erro" then
			pasta.Inconsistente.Value += 1
		elseif tipoDePorta == "Protan" then
			pasta.Protan.Value += 1
		elseif tipoDePorta == "Deutan" then
			pasta.Deutan.Value += 1
		end

		print("Resposta " .. tipoDePorta .. " registrada para " .. player.Name)

		-- LÓGICA DE TELEPORTE
		local destino = game.Workspace:FindFirstChild(nomeProximaSala)
		if destino and destino:FindFirstChild("Spawn") then
			personagem.HumanoidRootPart.CFrame = destino.Spawn.CFrame
		end

		task.wait(2) -- Tempo para evitar disparos duplos
		debounce = false
	end
end)