#if defined PrintChatIncluded
	#endinput
#endif

#define PrintChatIncluded

// Надёжность сообщения
stock bool:g_bPrintChatReliable;

/*
	[ PrintChat ]
	
	[ Описание ]
	Пишет сообщение в чат игроку/игрокам.
	Специальные сочетания букв и символы:
	^n - переход на следующую строку
	!r - красный цвет
	!g - зелёный цвет
	!y - жёлтый цвет
	!b - синий цвет
	!w - белый цвет
	!t - цвет команды
	!!! Внимание нельзя одновременно использовать красный, синий и белый цвета в одном сообщении !!!
	
	[ Аргументы ]
	| Название	| Тип			| По умолчанию			| Описание
	----------------------------------------------------------------------------------------
	| iEntity	| Целочисленное	| 0						| Индекс игрока которому писать сообщение (0 - всем)
	| iMessage	| Целочисленное |						| Сообщение
	| ...		|				|						| Аргументы к сообщению
	
	[ Примеры ]
	PrintChat(0, "!rВнимание!!!^nНе выдавайте никому свои логин и пароль!!!");
*/
stock PrintChat(iEntity = 0, const iMessage[], ...)
{
	// Подгружаем локальные глобальные переменные
	static iMsgSayText, iMsgTeamInfo, iMaxPlayers;
	
	if (!iMsgSayText) iMsgSayText = get_user_msgid("SayText");		// Индекс SayText
	if (!iMsgTeamInfo) iMsgTeamInfo = get_user_msgid("TeamInfo");	// Индекс TeamInfo
	if (!iMaxPlayers) iMaxPlayers = get_maxplayers();				// Макс. кол-во игроков
	
	// Сообщение
	new iBuffer[256];
	
	// Кол-во аргументов
	new iParams = numargs();
	
	// Посылатель и команда
	new iSender;
	new iTeam[10];
	
	// Отсылаем одному игроку
	if (iEntity)
	{
		// Заменяем все LANG_PLAYER, на ID получателя
		for (new iArg = 2, i; iArg < iParams - 1; iArg++)
		{
			// Если аргумент не равен LANG_PLAYER переходим к следующему аргументу
			if (getarg(iArg) != LANG_PLAYER)
				continue;
			
			// Обнуляем
			i = 0;
			
			// Получаем следующий аргумент - строку
			while ((iBuffer[i] = getarg(iArg + 1, i++))) {}
			
			// Если это не ML ключ переходим к следующему аргументу
			if (GetLangTransKey(iBuffer) == TransKey_Bad)
				continue;
			
			// Меняем численное значение аргумента
			setarg(iArg++, _, iEntity);
		}
		
		// Если аргументов больше 2 форматируем сообщение
		if (iParams > 2) vformat(iBuffer, charsmax(iBuffer), iMessage, 3);
		// Иначе копируем 2 аргумент
		else copy(iBuffer, charsmax(iBuffer), iMessage);
		
		// Белый цвет
		if (contain(iBuffer, "!w") != -1)
		{
			// Записываем
			iSender = iMaxPlayers + 1;
			iTeam = "SPECTATOR";
			
			// Заменяем
			while (replace(iBuffer, charsmax(iBuffer), "!w", "^3")) {}
		}
		// Красный цвет
		else if (contain(iBuffer, "!r") != -1)
		{
			// Записываем
			iSender = iMaxPlayers + 1;
			iTeam = "TERRORIST";
			
			// Заменяем
			while (replace(iBuffer, charsmax(iBuffer), "!r", "^3")) {}
		}
		// Синий
		else if (contain(iBuffer, "!b") != -1)
		{
			// Записываем
			iSender = iMaxPlayers + 1;
			iTeam = "CT";
			
			// Заменяем
			while (replace(iBuffer, charsmax(iBuffer), "!b", "^3")) {}
		}
		// Цвет команды
		else
		{
			// Записываем
			iSender = iEntity;
			
			// Заменяем
			while (replace(iBuffer, charsmax(iBuffer), "!t", "^3")) {}
		}
		
		// Заменяем жёлтый и зелёный
		while (replace(iBuffer, charsmax(iBuffer), "!y", "^1")) {}
		while (replace(iBuffer, charsmax(iBuffer), "!g", "^4")) {}
		
		format(iBuffer, charsmax(iBuffer), "^1%s", iBuffer);
		
		// Максимальная длина сообщения
		iBuffer[190] = EOS;
		
		// Если цвет не командный, то заменяем её на нужный цвет на несуществующем игроке
		if (iTeam[0])
		{
			message_begin(g_bPrintChatReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, iMsgTeamInfo, _, iEntity);
			write_byte(iMaxPlayers + 1);
			write_string(iTeam);
			message_end();
		}
		
		// Отсылаем сообщение
		message_begin(g_bPrintChatReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, iMsgSayText, _, iEntity);
		write_byte(iSender);
		write_string(iBuffer);
		message_end();
	}
	// Отсылаем всем
	else
	{
		// Количество аргументов, текущий аргумент
		new i, iChangeArgsCount, iArg;
		
		// Создаём динамический массив
		new Array:aMultiLang = ArrayCreate();
		
		// Записываем все аргументы содержащие LANG_PLAYER
		for (iArg = 2; iArg < iParams - 1; iArg++)
		{
			// Если аргумент не равен LANG_PLAYER переходим к следующему аргументу
			if (getarg(iArg) != LANG_PLAYER)
				continue;
			
			i = 0;
			
			// Получаем следующий аргумент
			while ((iBuffer[i] = getarg(iArg + 1, i++))) {}
			
			// Если это не ML ключ переходим к следующему аргументу
			if (GetLangTransKey(iBuffer) == TransKey_Bad)
				continue;
			
			// Записываем в массив
			ArrayPushCell(aMultiLang, iArg++);
			
			// Прибавляем
			iChangeArgsCount++;
		}
		
		// Если есть ML
		if (iChangeArgsCount)
		{
			// Массив из игроков
			new iPlayers[32];
			// Всего игроков
			new iPlayersCount;
			// Последний игрок
			new iPlayer;
			
			// Получаем игроков
			get_players(iPlayers, iPlayersCount);
			
			// Делаем цикл из игроков
			for (new i = 0; i < iPlayersCount; i++)
			{
				// Сохраняем последнего игрока
				iPlayer = iPlayers[i];
				
				// Меняем аргументы LANG_PLAYER на ID игрока
				for (iArg = 0; iArg < iChangeArgsCount; iArg++)
					setarg(ArrayGetCell(aMultiLang, iArg), _, iPlayer);
				
				// Форматируем сообщение
				vformat(iBuffer, charsmax(iBuffer), iMessage, 3);
				
				// Белый цвет
				if (contain(iBuffer, "!w") != -1)
				{
					// Записываем
					iSender = iMaxPlayers + 1;
					iTeam = "SPECTATOR";
					
					// Заменяем
					while (replace(iBuffer, charsmax(iBuffer), "!w", "^3")) {}
				}
				// Красный цвет
				else if (contain(iBuffer, "!r") != -1)
				{
					// Записываем
					iSender = iMaxPlayers + 1;
					iTeam = "TERRORIST";
					
					// Заменяем
					while (replace(iBuffer, charsmax(iBuffer), "!r", "^3")) {}
				}
				// Синий цвет
				else if (contain(iBuffer, "!b") != -1)
				{
					// Записываем
					iSender = iMaxPlayers + 1;
					iTeam = "CT";
					
					// Заменяем
					while (replace(iBuffer, charsmax(iBuffer), "!b", "^3")) {}
				}
				// Цвет команды
				else
				{
					// Записываем
					iSender = iPlayer;
					iTeam[0] = EOS;
					
					// Заменяем
					while (replace(iBuffer, charsmax(iBuffer), "!t", "^3")) {}
				}
				
				// Заменяем
				while (replace(iBuffer, charsmax(iBuffer), "!y", "^1")) {}
				while (replace(iBuffer, charsmax(iBuffer), "!g", "^4")) {}
				
				format(iBuffer, charsmax(iBuffer), "^1%s", iBuffer);
				
				// Максимальная длина сообщения
				iBuffer[190] = EOS;
				
				// Если цвет не командный, то заменяем её на нужный цвет на несуществующем игроке
				if (iTeam[0])
				{
					message_begin(g_bPrintChatReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, iMsgTeamInfo, _, iPlayer);
					write_byte(iSender);
					write_string(iTeam);
					message_end();
				}
				
				// Отсылаем сообщение
				message_begin(g_bPrintChatReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, iMsgSayText, _, iPlayer);
				write_byte(iSender);
				write_string(iBuffer);
				message_end();
			}
		}
		// ML нет
		else
		{
			// Если аргументов больше 2 форматируем сообщение
			if (iParams > 2) vformat(iBuffer, charsmax(iBuffer), iMessage, 3);
			// Иначе получаем копируем 2 аргумент
			else copy(iBuffer, charsmax(iBuffer), iMessage);
			
			// Белый цвет
			if (contain(iBuffer, "!w") != -1)
			{
				// Записываем
				iTeam = "SPECTATOR";
				
				// Заменяем
				while (replace(iBuffer, charsmax(iBuffer), "!w", "^3")) {}
			}
			// Красный цвет
			else if (contain(iBuffer, "!r") != -1)
			{
				// Записываем
				iTeam = "TERRORIST";
				
				// Заменяем
				while (replace(iBuffer, charsmax(iBuffer), "!r", "^3")) {}
			}
			// Синий цвет
			else if (contain(iBuffer, "!b") != -1)
			{
				// Записываем
				iTeam = "CT";
				
				// Заменяем
				while (replace(iBuffer, charsmax(iBuffer), "!b", "^3")) {}
			}
			// Цвет команды
			else
				// Заменяем
				while (replace(iBuffer, charsmax(iBuffer), "!t", "^3")) {}
			
			// Заменяем
			while (replace(iBuffer, charsmax(iBuffer), "!y", "^1")) {}
			while (replace(iBuffer, charsmax(iBuffer), "!g", "^4")) {}
			
			format(iBuffer, charsmax(iBuffer), "^1%s", iBuffer);
			
			// Максимальная длина сообщения
			iBuffer[190] = EOS;
			
			// Если цвет не командный, то заменяем её на нужный цвет на несуществующем игроке
			if (iTeam[0])
			{
				message_begin(g_bPrintChatReliable ? MSG_ALL : MSG_BROADCAST, iMsgTeamInfo);
				write_byte(iMaxPlayers + 1);
				write_string(iTeam);
				message_end();
				
				// Отсылаем
				message_begin(g_bPrintChatReliable ? MSG_ALL : MSG_BROADCAST, iMsgSayText);
				write_byte(iMaxPlayers + 1);
				write_string(iBuffer);
				message_end();
			}
			// Цвет команды
			else
			{
				// Массив из игроков
				new iPlayers[32];
				// Всего игроков
				new iPlayersCount;
				// Последний игрок
				new iPlayer;
				
				// Получаем игроков
				get_players(iPlayers, iPlayersCount);
				
				// Делаем цикл из игроков
				for (new i = 0; i < iPlayersCount; i++)
				{
					// Сохраняем последнего игрока
					iPlayer = iPlayers[i];
					
					// Отсылаем
					message_begin(g_bPrintChatReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, iMsgSayText, _, iPlayer);
					write_byte(iPlayer);
					write_string(iBuffer);
					message_end();
				}
			}
		}
		
		// Удаляем массив
		ArrayDestroy(aMultiLang);
	}
}

/*
	[ PrintChatReliable ]
	
	[ Описание ]
	Изменяет надёжность отправки сообщения в чат.
	!!! Внимание если не знаете зачем это, не используйте !!!
	
	[ Аргументы ]
	| Название	| Тип			| По умолчанию			| Описание
	----------------------------------------------------------------------------------------
	| bReliable	| Булевая		| false					| Надёжность
	
	[ Примеры ]
	PrintChatReliable(false);
	PrintChatReliable(true);
*/
stock PrintChatReliable(bool:bReliable = false) g_bPrintChatReliable = bReliable;