local label = script.Parent
local modelo = label.Parent.Parent.Parent
local gatilho = modelo:WaitForChild("GatilhoFinal")

local DataStoreService = game:GetService("DataStoreService")
local ClinicaDataStore = DataStoreService:GetDataStore("BancoDadosTCC_Fuzzy")
local CHAVE_MESTRA = "ListaPacientes"
local HttpService = game:GetService("HttpService")

-- ==========================================
-- SALVAMENTO NO BANCO DE DADOS (TCC)
-- ==========================================
local function salvarDadosNoBanco(player, diagnostico, tipoDalt, scoreAQ, pN, pL, pM, pS, pCons, pInc, trajetoStr, tabelaTempos, tempoTotal)
	local sucesso, erro = pcall(function()
		local listaGlobal = ClinicaDataStore:GetAsync(CHAVE_MESTRA) or {}
		local novoRegistro = {
			Nome = player.Name,
			UserId = player.UserId,
			Diagnostico = diagnostico,
			TipoDaltonismo = tipoDalt,
			ScoreAQ = scoreAQ,
			PctNormal = pN,    
			PctLeve = pL,        
			PctModerado = pM,  
			PctSevero = pS,
			PctConsistencia = pCons,
			PctInconsistencia = pInc,
			TempoTotalSec = tempoTotal,
			TemposSalas = tabelaTempos,
			Trajeto = trajetoStr,
			Timestamp = os.date("%Y-%m-%d %H:%M:%S")
		}
		table.insert(listaGlobal, novoRegistro)
		ClinicaDataStore:SetAsync(CHAVE_MESTRA, listaGlobal)
	end)

	if sucesso then print("💾 [BANCO FUZZY] Matriz salva para " .. player.Name)
	else warn("❌ [BANCO FUZZY] Erro ao salvar: " .. tostring(erro)) end
end

-- ==========================================
-- MOTOR MATEMÁTICO FUZZY
-- ==========================================
local function calcularScoreETextos(errosTotais, errosProtan, errosDeutan, erroInconsistencia)
	-- O mesmo motor Mamdani compacto para calcular os percentuais
	local function calcP(x) return x <= 6 and math.max(0, (6-x)/4) or 0 end
	local function calcL(x) return (x>0 and x<=2.5) and (x<=1 and x or (2.5-x)/1.5) or 0 end
	local function calcM(x) return (x>=1.5 and x<=4) and (x<=2 and (x-1.5)/0.5 or (x<=3 and 1 or (4-x))) or 0 end
	local function calcS(x) return x >= 3 and math.min(1, (x-3)/1) or 0 end

	local rgN = errosTotais <= 6 and math.max(0, (6-errosTotais)/4) or 0
	local rgM = (errosTotais >= 3 and errosTotais <= 20) and (errosTotais <= 7 and (errosTotais-3)/4 or (errosTotais <= 15 and 1 or (20-errosTotais)/5)) or 0
	local rgS = errosTotais >= 16 and math.min(1, (errosTotais-16)/4) or 0

	local pL, pM, pS = calcL(errosProtan), calcM(errosProtan), calcS(errosProtan)
	local dL, dM, dS = calcL(errosDeutan), calcM(errosDeutan), calcS(errosDeutan)

	local r_SD  = math.min(rgS, dS)
	local r_MoD = math.max(math.min(rgM, dM), math.min(rgS, dM), math.min(rgM, dS))
	local r_MiD = math.max(math.min(rgN, dL), math.min(rgM, dL))
	local r_N   = rgN
	local r_MiP = math.max(math.min(rgN, pL), math.min(rgM, pL))
	local r_MoP = math.max(math.min(rgM, pM), math.min(rgS, pM), math.min(rgM, pS))
	local r_SP  = math.min(rgS, pS)

	local scoreAQ = 0
	local somaAreas = r_SD + r_MoD + r_MiD + r_N + r_MiP + r_MoP + r_SP
	if somaAreas > 0 then 
		scoreAQ = ((r_SD * -8) + (r_MoD * -5) + (r_MiD * -2) + (r_MiP * 2) + (r_MoP * 5) + (r_SP * 8)) / somaAreas 
	end

	local diagFinal = "Visão Normal"
	local tipo = "Nenhum"
	if scoreAQ <= -6 then diagFinal = "Deuteranomalia Severa"; tipo = "Deutan"
	elseif scoreAQ <= -3 then diagFinal = "Deuteranomalia Moderada"; tipo = "Deutan"
	elseif scoreAQ < -0.5 then diagFinal = "Deuteranomalia Leve"; tipo = "Deutan"
	elseif scoreAQ >= 6 then diagFinal = "Protanomalia Severa"; tipo = "Protan"
	elseif scoreAQ >= 3 then diagFinal = "Protanomalia Moderada"; tipo = "Protan"
	elseif scoreAQ > 0.5 then diagFinal = "Protanomalia Leve"; tipo = "Protan" end

	local pInc = 0
	if erroInconsistencia == 1 then pInc = 33 elseif erroInconsistencia == 2 then pInc = 66 elseif erroInconsistencia > 2 then pInc = math.min(100, erroInconsistencia * 10) end
	local pCons = 100 - pInc

	if pInc >= 70 then
		diagFinal = "Inconsistente"
		tipo = "N/A"
	end

	return diagFinal, tipo, scoreAQ, math.floor(r_N*100), math.floor(math.max(r_MiP, r_MiD)*100), math.floor(math.max(r_MoP, r_MoD)*100), math.floor(math.max(r_SP, r_SD)*100), pCons, pInc
end

local function gerarFalaDoChefe(player, diagnosticoFinal, pCons, scoreAQ)
	local saudacao = "Olá, " .. player.Name .. "! Muito obrigado por concluir o percurso.\n\n"
	if diagnosticoFinal == "Inconsistente" then
		return saudacao .. '"Notei muitas hesitações ou escolhas contraditórias no trajeto. A consistência foi de apenas ' .. pCons .. '%. Recomendo que faça o percurso novamente!"'
	elseif diagnosticoFinal == "Visão Normal" then
		return saudacao .. '"Analisei a consistência (' .. pCons .. '%) e o seu Score (AQ: '..string.format("%.2f", scoreAQ)..') indica visão normal. Bom trabalho!"'
	else
		return saudacao .. '"Analisando seus dados (' .. pCons .. '% de consistência, Score AQ: '..string.format("%.2f", scoreAQ)..'), percebemos uma anomalia de grau **' .. string.upper(diagnosticoFinal) .. '** no seu perfil. Vamos adaptar a sua estação!"'
	end
end

-- ==========================================
-- PROCESSAMENTO GATILHO
-- ==========================================
gatilho:GetAttributeChangedSignal("ProcessarPlayer"):Connect(function()
	local nomePlayer = gatilho:GetAttribute("ProcessarPlayer")
	if nomePlayer == "" then return end

	local player = game.Players:FindFirstChild(nomePlayer)
	if player then
		local pasta = player:FindFirstChild("ResultadosDaltonismo")
		if pasta then
			local d = pasta:FindFirstChild("Deficiente") and pasta.Deficiente.Value or 0
			local p = pasta:FindFirstChild("Protan") and pasta.Protan.Value or 0
			local dt = pasta:FindFirstChild("Deutan") and pasta.Deutan.Value or 0
			local err = pasta:FindFirstChild("Inconsistente") and pasta.Inconsistente.Value or 0
			local errosTotais = d + p + dt

			local trajetoJSON = player:FindFirstChild("JSON_Trajeto") and player.JSON_Trajeto.Value or "[]"

			local tempoTotal = 0
			local horaSpawn = player:GetAttribute("HoraSpawn")
			if horaSpawn then tempoTotal = math.floor((os.clock() - horaSpawn) * 100) / 100 end

			local tabelaTempos = {}
			local pastaTempo = player:FindFirstChild("TemposSalas") or player:FindFirstChild("ResultadosTempo")
			if pastaTempo then
				for _, val in pairs(pastaTempo:GetChildren()) do
					if val:IsA("NumberValue") then tabelaTempos[val.Name] = math.floor(val.Value * 100) / 100 end
				end
			end

			local diagFinal, tipoDalt, scoreAQ, pN, pL, pM, pS, pCons, pInc = calcularScoreETextos(errosTotais, p, dt, err)
			label.Text = gerarFalaDoChefe(player, diagFinal, pCons, scoreAQ)

			salvarDadosNoBanco(player, diagFinal, tipoDalt, scoreAQ, pN, pL, pM, pS, pCons, pInc, trajetoJSON, tabelaTempos, tempoTotal)
		end
		task.wait(1)
		gatilho:SetAttribute("ProcessarPlayer", "")
	end
end)