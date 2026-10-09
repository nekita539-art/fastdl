/*Check the Query on some problems.*/
stock bool:CheckQuery(FailState, ErrCode, Error[])
{
	if(FailState == TQUERY_SUCCESS)
        	return true;
	else
		if(FailState == TQUERY_CONNECT_FAILED)
			log_amx("Load - Could not connect to SQL database.  [%d] %s", ErrCode, Error);
		else if(FailState == TQUERY_QUERY_FAILED)
    			log_amx("Load Query failed. [%d] %s", ErrCode, Error);

	return false;
}

/*Format the query string.*/
stock SQL_ThreadQueryFormat(Handle:Db_Tuple, const handler[], const query[], const data[]="", dataSize=0, any:...)
{
	new szQueryFormat[256];
	vformat(szQueryFormat, charsmax(szQueryFormat), query, 6)
   
	return SQL_ThreadQuery(Db_Tuple, handler, szQueryFormat, data, dataSize)	
}

/*Fromat the query string without data.*/
stock SQL_ThreadQueryFormatNoData(Handle:Db_Tuple, const handler[], const query[], any:...)
{
	new szQueryFormat[256];
    	vformat(szQueryFormat, charsmax(szQueryFormat), query, 4)
    
	return SQL_ThreadQuery(Db_Tuple, handler, szQueryFormat)	
}

/*Check table on exists.*/
stock bool:SQL_TableExists(Handle:db, const table[])
{
	new Handle:query = SQL_PrepareQuery(db,"SELECT * FROM information_schema.tables WHERE table_name = '%s' LIMIT 1;", table);
    	new g_Error[512]
    
    	if (!SQL_Execute(query))
    	{
        	SQL_QueryError(query,g_Error,charsmax(g_Error));
        	set_fail_state(g_Error);
    	}
    	else if(!SQL_NumResults(query))
    	{
        	SQL_FreeHandle(query);
        	return false;	
    	}
	SQL_FreeHandle(query);

    	return true;
}