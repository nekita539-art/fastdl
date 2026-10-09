////////////////////*** JailBreak 2014 ***////////////////////
////////////////////*** By Opo4uMapy ***//////////////////////
////////////////////*** Skype and Site: Lovely-CS.Ru ***//////////////////////

/*###################################ENUM###################################*/
/*###################################ENUM###################################*/

enum
{
	ALL_GAME = 0,	//форвард сработает при запуске ЛЮБОЙ игры, а другие значание для других игр
	ZOMBIE,			//Зомби
	HIDE,			//Прятки
	PODRIVATELI,		//Подрыватели
	MAGIYA,			//Магия
	VISHIBALO,		//Вышибалы
	CHAY_CHAY,		//Чай-Чай Выручай
	SHTURM,			//Штурм
	NEVEDIMKI		//Неведимки
}
enum
{
	PALO = 0,
	OTVERTKA,
	MACHETE,
	LOM,
	STRIP_ALL
}
enum
{
	WIN_NO_ONE = 0,
	WIN_PRISONERS,
	WIN_GUARDS
}

/*#################################Форварды#################################*/
/*#################################Форварды#################################*/

/** [ jb_round_game ]
	* Вызывается по началу игр
	* 
	* 'game' - Индекс запущеной игры
*/
forward jb_round_game(game)

/*#################################*/

/** [ jb_round_end ]
	
	* Вызывается по окнчанию раунда.
	* 
	* 'WinTeam' - Индкс победившей команды.
	
	* [ 'WinTeam' ]	
	* 'WIN_GUARDS' - Охранники выйграли раунд.
	* 'WIN_PRISONERS' - Заключённые выйграли раунд.
	* 'WIN_NO_ONE' - Ни одна команда не выйграла раунд.
*/
forward jb_round_end(WinTeam)
/*#################################Нативы#################################*/
/*#################################Нативы#################################*/

///***Вовращает дни недели 5 - суббота, 6 - воскресение***///
native JailDay()

///***Возвращает запуск дуели***///
native jb_get_duel()

///***Возвращает саймона***///
native bool:jb_get_user_simon(index)

///***Возвращает зэк фд или нет***///
native bool:jb_get_fd(index)

///***Возвращает зэк бунтующий или нет***///
native bool:jb_get_wanted(index)

///***Возвращает есть последний зэк или нет ***///
native jb_get_last(index)

///***Возвращает запуск бокса true - вкл, false - выкл***///
native bool:jb_get_user_box()

/** [ jb_get_gamemode ]

	* Возвращает тип мода.

	* '0' - Глобальный Свободный день(Free Day)
	* '1' - Обычный День
	* '2' - Зомби день
	* '3' - Прятки
	* '4' - Подрыватели
	* '5' - Магичиский день
	* '6' - Штурм
	* '7' - Неведимки
	
*/
native jb_get_gamemode()

/** [ jb_set_game ]

	* Запускает игру.
	* 'num' - Игра

	['num']
	* 'ZOMBIE	'				//Зомби
	* 'HIDE'					//Прятки
	* 'PODRIVATELI'			//Подрыватели
	* 'MAGIYA'				//Магия
	* 'VISHIBALO'				//Вышибалы
	* 'CHAY_CHAY'			//Чай-Чай Выручай
	* 'SHTURM'				//Штурм
	* 'NEVEDIMKI'				//Неведимки

	######
	P.S (Стандартно) Данную функцию использовать только в субботу и в воскресеньи(игровых раундов) и в VoteGame [API] плагине
	т.к могут быть баги.
	
*/
native jb_set_game(num)

/** [ jb_set_freeday ]

	* Выдает игроку свободный день.

	* 'index' - Индекс игрока.
*/
native jb_set_freeday(index)

/** [ jb_set_user_wanted ]

	* Заберает у игрока бунтаря.

	* 'index' - Индекс игрока.
*/
native jb_clear_user_wanted(index)

/** [ jb_set_user_model ]

	* Устанавливает модель игроку.

	* 'index' - Индекс игрока.
	* 'szModel' - Устанавливаемая модель

	['Пример']
	jb_set_user_model(index, "new_model")
	
*/
native jb_set_user_model(index, const szModel[])

///***меняет модель на изначальную**///
native jb_reset_user_model(index)

///***Возвращает текущию модель игрока***///
native jb_get_user_model(index, const szModel[], iLen)

/** [ jb_set_user_cold_weapons ]

	* Выдает игроку одно из выбраных холодных оружий.

	* 'index' - Индекс игрока.
	* 'num' - Выдаваемое орудие

	['num']
	* 'PALO'			- Вантуз
	* 'OTVERTKA'		- Отвертка
	* 'MACHETE'		- Мачете
	* 'LOM'			- Лом
	
*/
native jb_set_user_cold_weapons(index, num)

/** [ jb_get_user_cold_weapons ]

	* Возвращает есть ли у игрока или нет одно из выбраных холодных оружий.

	* 'index' - Индекс игрока.
	* 'num' - Оружие, значение которого нужно получить

	['num']
	* 'PALO'			- Вантуз
	* 'OTVERTKA'		- Отвертка
	* 'MACHETE'		- Мачете
	* 'LOM'			- Лом
	
*/
native jb_get_user_cold_weapons(index, num)

/** [ jb_strip_user_cold_weapons ]

	* Забирает одно из указаных холодных оружий.

	* 'index' - Индекс игрока.
	* 'num' - Оружие которое нужно забрать

	['num']
	* 'PALO'			- Заберает Вантуз
	* 'OTVERTKA'		- Заберает Отвертку
	* 'MACHETE'		- Заберает Мачете
	* 'LOM'			- Заберает Лом
	* 'STRIP_ALL'		- Заберает все холодные оружия
	
*/
native jb_strip_user_cold_weapons(index, num)

/** [ jb_set_user_voice ]

	* Выдает/заберает голос
	
	* 'index' - Индекс игрока.
*/
native jb_set_user_voice(index)

/** [ jb_get_user_voice ]

	* Возвращает есть голос у игрока или нет
	
	* 'index' - Индекс игрока.
*/
native bool:jb_get_user_voice(index)

/** [ jb_get_user_in_duel ]

	* Проверяет учствует игрок в дуели или нет
	
	* 'index' - Индекс игрока.
*/
native bool:jb_get_user_in_duel(index)

/** [ jb_block_user_weapons ]

	* Блокирует подбор, выброс и выбор оружия определённому игроку.
	
	* 'index' - Индекс игрока.
	* 'iMode' - Влючение/Отключение блока.

	* [ 'iMode' ]
	* 'true' - Блок влючён.
	* 'false' - Блок выключен.
*/
native jb_block_user_weapons(index, bool:iMode)

/** [ Round_restart ]

	* Возвращает запущен рестарт раунда или нет
*/
native bool:Round_restart()

///***Открывает клетки***///
native jb_open_doors()

///***Открывает меню Футболла***///
native open_football_menu(index)

///***Выдает магичискую палку***///
native give_rifle(index)

///***Выдает Ak47 Gold***///
native give_ak47gold(index)

///***Выдает MG3***///
native give_mg3(index)

///***Выдает Dual Infinity Red***///
native give_infinir(index)

///***Выдает MG3***///
native give_m200(index)

///***Выдает Джамп-Гранату***///
native give_jump_bomb(index)

///***Выдает Гранату-Конфузию***///
native give_conc_bomb(index)

///***Выдает Адреналин***///
native jb_set_adrenaline(id)

///***Возвращает есть у игрока адреналин или нет***///
native jb_get_adrenaline(id)

///***Запускает игру Чай-Чай Выручай***///
native Chay_Chay()

///***Возвращает включена игра Чай-Чай Выручай 1 - вкл, 0 - выкл***///
native jb_get_chay()

///***Возвращает включена игра Вышибалы 1 - вкл, 0 - выкл ***///
native is_game_killball()

///***Запускает Игру Вышибалы***///
native jb_game_killball()