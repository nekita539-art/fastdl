  ////////////////////////////////////////
 ///***** Нативы от Жаил сервера *****///
////////////////////////////////////////


//***** Всё для Саймона *****//
native jb_is_user_simon(id)
native jb_set_user_freeday(id)
native jb_give_simon(id)
native jb_simon_menu(id)

//***** Всё для Авторитета *****//
native jb_is_user_thief(id)
native jb_give_thief(id)
native jb_thief_menu(id)

//***** Остальные Нативы *****//
native jb_set_user_fake_skin(id)
native jb_show_lr_menu(id)
native jb_show_shop(id)
native jb_get_user_skull(id)
native jb_set_user_skull(id, amount)
native jb_weapon_jumpgrenade(id)
native jb_count_new(id)
native jb_show_vipmenu(id)
native jb_is_user_last()
native jb_open_doors()
native is_free_day()

//***** Мои Игры *****//

	// Прятки
native jb_game_hide(id)
native is_hide_day()
native is_hide_day_after()

	// Бокс
native jb_game_box(id)
native is_game_box()

	// Футбол
native jb_game_football(id)
native is_game_football()

	// Снайперы
native jb_game_snipers(id)
native is_game_snipers()

	// Невидимки
native jb_game_invisible(id)
native is_game_invisible()