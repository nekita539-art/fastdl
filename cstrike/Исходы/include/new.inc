#include <cstrike>
#include <amxmodx>



stock color_chat(const id, const input[], any:...)
{ 
    new iCount = 1, iPlayers[32]

    static szMsg[191]
    vformat(szMsg, charsmax(szMsg), input, 3)

    replace_all(szMsg, 190, "/g", "^4")
    replace_all(szMsg, 190, "/y", "^1")
    replace_all(szMsg, 190, "/ctr", "^3")
    replace_all(szMsg, 190, "/w", "^0")

    if(id) iPlayers[0] = id
    else get_players(iPlayers, iCount, "ch")

    for (new i = 0; i < iCount; i++)
    {
        if (is_user_connected(iPlayers[i]))
        {
            message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, iPlayers[i])
            write_byte(iPlayers[i])
            write_string(szMsg)
            message_end()
        }
    }
}