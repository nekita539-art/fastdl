/* Re.Act!ve Nativies functions
*
* by the Re.Act!ve
*  originally developed by OLO
*
* This file is provided as is (no warranties).
*/

/* Native & Forward functions AMXX with by creator Re.Act!ve
* Функция вызывается, когда игрок (id = index) выбирает, либо меняет класс (classid)
* по этой функции можно задавать параметры для каждого класса */
forward cl_choosen_class(index, classid)

/* Native & Forward functions AMXX with by creator Re.Act!ve
* Функция вызывается, когда игрок регистрирует новый класс
* name[] - Название класса. Вы можете дать любое название для класса (исключайте совпадения), чтобы использовать их для вывода в меню.
* model[] - Модель игрока для класса.
* clawmodel[] - Модели рук для этого класса.
* len - Количество символов в команде. Например в "/give_class" (кавычки не берем) - 11 символов (кстати, пробел тоже символ)*/
native cl_register_class(const name[], const model[], const clawmodel[], health, Float:gravity)

/* Native & Forward functions AMXX with by creator Re.Act!ve
* Функция получает id номер класса.
* index - Номер (id) игрока */
native cl_get_user_classid(index)

/* Native & Forward functions AMXX with by creator Re.Act!ve
* Функция вызывается, когда игрок регистрирует новый класс
* index - Номер (id) игрока, для которого следует изменить класс
* classid - номер класса, который необходимо присвоить игроку. */
native cl_set_user_class(index, classid)

/* Native & Forward functions AMXX with by creator Re.Act!ve
* Функция Native логического типа, которая получает имеет ли игрок id какой-либо класс
* index - Номер (id) игрока, для которого следует изменить класс*/
native cl_is_user_class(index)

/* Native & Forward functions AMXX with by creator Re.Act!ve
* Функция Native логического типа, которая получает 1 или 0 в зависимости от выполнения
* index - Номер (id) игрока, для которого следует изменить класс
* name[] - Имя класса, должно быть в кавычках, который необходимо выдать игроку */
native cl_give_class(name[], index)
