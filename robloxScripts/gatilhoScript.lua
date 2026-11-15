local gatilho = script.Parent
local modeloDasPortas = gatilho.Parent

-- CONFIGURAÇÃO DA PORTA: Ajuste apenas o tipo ("Normal", "Daltonico", "Erro", "Protan", "Deutan")
local tipoDePorta = "Normal" 

-- EXTRAÇÃO AUTOMÁTICA DO NÚMERO DA SALA PELO NOME DO MODELO/SALA
local numeroDaSala = tonumber(string.match(gatilho:GetFullName(), "%d+")) or 1

gatilho.Touched:Connect(function(hit)
	local personagem = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(personagem)

	if player then
		if modeloDasPortas:GetAttribute("Trancado") then return end
		modeloDasPortas:SetAttribute("Trancado", true) 

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

		-- PARADA E CÁLCULO DO TEMPO DA SALA
		local tempoEntrada = player.TempoEntradaSalaAtual.Value
		if tempoEntrada > 0 then
			local tempoGasto = os.clock() - tempoEntrada
			local nomeChaveSala = "Sala_" .. string.format("%02d", numeroDaSala)
			local tempoPart = player.TemposSalas:FindFirstChild(nomeChaveSala)
			if tempoPart then
				tempoPart.Value = math.floor(tempoGasto * 100) / 100
			end
		end

		print("Resposta " .. tipoDePorta .. " na Sala " .. numeroDaSala .. " registrada para " .. player.Name)
	end
end)

gatilho.TouchEnded:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)

	if player and modeloDasPortas:GetAttribute("Trancado") == true then
		if modeloDasPortas:GetAttribute("FisicamenteFechado") then return end
		modeloDasPortas:SetAttribute("FisicamenteFechado", true)

		task.wait(0.6)

		for _, porta in pairs(modeloDasPortas:GetChildren()) do
			if porta:IsA("BasePart") then
				porta.Color = Color3.fromRGB(0, 0, 0)
				porta.Transparency = 0
				porta.CanCollide = true
			end
		end

		print("Todas as portas do modelo " .. modeloDasPortas.Name .. " foram trancadas.")
	end
end)