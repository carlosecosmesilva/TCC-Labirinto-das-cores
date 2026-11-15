game.Players.PlayerAdded:Connect(function(player)
	-- 1. Pasta de Resultados de Daltonismo
	local stats = Instance.new("Folder", player)
	stats.Name = "ResultadosDaltonismo"

	Instance.new("IntValue", stats).Name = "Normal"
	Instance.new("IntValue", stats).Name = "Deficiente"
	Instance.new("IntValue", stats).Name = "Protan"
	Instance.new("IntValue", stats).Name = "Deutan"
	Instance.new("IntValue", stats).Name = "Inconsistente"

	-- 2. Pasta de Métricas de Tempo por Sala
	local tempos = Instance.new("Folder", player)
	tempos.Name = "TemposSalas"

	for i = 1, 24 do
		local tempoSala = Instance.new("NumberValue", tempos)
		tempoSala.Name = "Sala_" .. string.format("%02d", i)
		tempoSala.Value = 0
	end

	-- 3. Temporizadores e Controle Global
	local tempoEntradaSalaAtual = Instance.new("NumberValue", player)
	tempoEntradaSalaAtual.Name = "TempoEntradaSalaAtual"

	local tempoTotalGeral = Instance.new("NumberValue", player)
	tempoTotalGeral.Name = "TempoTotalGeral"

	-- Marca o momento inicial do Spawn
	player:SetAttribute("HoraSpawn", os.clock())

	print("Perfil completo de telemetria inicializado para: " .. player.Name)
end)