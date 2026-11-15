local label = script.Parent

-- ==========================================
-- MOTOR MATEMÁTICO FUZZY (MAMDANI - AQ)
-- ==========================================
local function fuzzificarEntradas(errosTotais, errosProtan, errosDeutan)
	local f = { RG_N = 0, RG_M = 0, RG_S = 0, P_N = 0, P_L = 0, P_M = 0, P_S = 0, D_N = 0, D_L = 0, D_M = 0, D_S = 0 }
	if errosTotais <= 6 then f.RG_N = math.max(0, (6 - errosTotais) / 4) end
	if errosTotais >= 3 and errosTotais <= 20 then
		if errosTotais <= 7 then f.RG_M = (errosTotais - 3) / 4
		elseif errosTotais <= 15 then f.RG_M = 1
		else f.RG_M = (20 - errosTotais) / 5 end
	end
	if errosTotais >= 16 then f.RG_S = math.min(1, (errosTotais - 16) / 4) end

	local function calcEixo(val)
		local r = { N = 0, L = 0, M = 0, S = 0 }
		if val <= 1.5 then r.N = math.max(0, (1.5 - val) / 1.5) end
		if val > 0 and val <= 2.5 then r.L = val <= 1 and (val / 1) or ((2.5 - val) / 1.5) end
		if val >= 1.5 and val <= 4 then
			if val <= 2 then r.M = (val - 1.5) / 0.5 elseif val <= 3 then r.M = 1 else r.M = (4 - val) / 1 end
		end
		if val >= 3 then r.S = math.min(1, (val - 3) / 1) end
		return r
	end

	local resP = calcEixo(errosProtan)
	f.P_N, f.P_L, f.P_M, f.P_S = resP.N, resP.L, resP.M, resP.S
	local resD = calcEixo(errosDeutan)
	f.D_N, f.D_L, f.D_M, f.D_S = resD.N, resD.L, resD.M, resD.S
	return f
end

local function calcularScoreDiagnostico(f)
	local r_SD  = math.min(f.RG_S, f.D_S)
	local r_MoD = math.max(math.min(f.RG_M, f.D_M), math.min(f.RG_S, f.D_M), math.min(f.RG_M, f.D_S))
	local r_MiD = math.max(math.min(f.RG_N, f.D_L), math.min(f.RG_M, f.D_L))
	local r_N   = f.RG_N
	local r_MiP = math.max(math.min(f.RG_N, f.P_L), math.min(f.RG_M, f.P_L))
	local r_MoP = math.max(math.min(f.RG_M, f.P_M), math.min(f.RG_S, f.P_M), math.min(f.RG_M, f.P_S))
	local r_SP  = math.min(f.RG_S, f.P_S)

	local somaPesos = (r_SD * -8) + (r_MoD * -5) + (r_MiD * -2) + (r_N * 0) + (r_MiP * 2) + (r_MoP * 5) + (r_SP * 8)
	local somaAreas = r_SD + r_MoD + r_MiD + r_N + r_MiP + r_MoP + r_SP

	local scoreAQ = 0
	if somaAreas > 0 then scoreAQ = somaPesos / somaAreas end
	return scoreAQ
end

local function obterTextosFuzzy(scoreAQ)
	local diagTexto = "Visão Normal"
	if scoreAQ <= -6 then diagTexto = "Deuteranomalia Severa"
	elseif scoreAQ <= -3 then diagTexto = "Deuteranomalia Moderada"
	elseif scoreAQ < -0.5 then diagTexto = "Deuteranomalia Leve"
	elseif scoreAQ >= 6 then diagTexto = "Protanomalia Severa"
	elseif scoreAQ >= 3 then diagTexto = "Protanomalia Moderada"
	elseif scoreAQ > 0.5 then diagTexto = "Protanomalia Leve" end
	return diagTexto
end

-- ==========================================
-- PROCESSAR RESULTADO
-- ==========================================
local function processarResultadoImediato(player)
	local pasta = player:FindFirstChild("ResultadosDaltonismo")
	if not pasta then 
		label.Text = "ERRO: DADOS DO PACIENTE NÃO ENCONTRADOS"
		return 
	end

	local n = pasta:FindFirstChild("Normal") and pasta.Normal.Value or 0
	local d = pasta:FindFirstChild("Deficiente") and pasta.Deficiente.Value or 0
	local p = pasta:FindFirstChild("Protan") and pasta.Protan.Value or 0
	local dt = pasta:FindFirstChild("Deutan") and pasta.Deutan.Value or 0
	local erro = pasta:FindFirstChild("Inconsistente") and pasta.Inconsistente.Value or 0

	local totalRespondido = n + d + p + dt
	local errosTotais = d + p + dt

	local laudo = "SISTEMA DE DIAGNÓSTICO (MAMDANI)\n"
	laudo = laudo .. "------------------------------------\n"
	laudo = laudo .. "PACIENTE: " .. player.Name .. "\n\n"

	if totalRespondido < 12 then
		laudo = laudo .. "STATUS: AGUARDANDO CONCLUSÃO DO TESTE\n"
		laudo = laudo .. "Total de placas respondidas: " .. totalRespondido .. "/23\n"
		label.TextColor3 = Color3.fromRGB(255, 255, 0)
	else
		local f = fuzzificarEntradas(errosTotais, p, dt)
		local scoreAQ = calcularScoreDiagnostico(f)
		local diagnostico = obterTextosFuzzy(scoreAQ)

		laudo = laudo .. "DIAGNÓSTICO: " .. diagnostico .. "\n"
		laudo = laudo .. string.format("SCORE (AQ): %.2f\n\n", scoreAQ)
		label.TextColor3 = Color3.fromRGB(0, 255, 0)
	end

	laudo = laudo .. "\n--- RESUMO DE PONTOS ---\n"
	laudo = laudo .. "Erros Gerais R/G: " .. errosTotais .. "\n"
	laudo = laudo .. "Erros Protan: " .. p .. "\n"
	laudo = laudo .. "Erros Deutan: " .. dt .. "\n"
	laudo = laudo .. "Inconsistências (Telemetria): " .. erro

	label.Text = laudo
end

local gatilho = game.Workspace:WaitForChild("GatilhoFinal")
local debounce = false

gatilho.Touched:Connect(function(hit)
	if debounce then return end
	local personagem = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(personagem)

	if player then
		debounce = true
		processarResultadoImediato(player)
		-- Este sinal avisa os outros dois scripts que o jogador chegou ao fim!
		gatilho:SetAttribute("ProcessarPlayer", player.Name)
		task.wait(2)
		debounce = false
	end
end)