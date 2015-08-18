<cfcomponent extends="com.sebtools.Records">

<cffunction name="addItem" access="public" returntype="void" output="no">
	<cfargument name="FeedID" type="numeric" required="yes">
	<cfargument name="link" type="string" required="yes">
	
	<cfif NOT hasItems(FeedID=arguments.FeedID,link=arguments.link)>
		<cfset variables.DataMgr.insertRecord(
			tablename=variables.table,
			data=arguments,
			truncate=true,
			onexists="skip"
		)>
	</cfif>
	
</cffunction>

<cffunction name="getItems" access="public" returntype="query" output="no">
	<cfargument name="FeedID" type="numeric" required="no">
	
	<!---
	If no scheduler is available, then we will have to see if an update check is needed every time
	Fortunately, this will usually just result in one small (one record, two column) database query
	--->
	<cfif
			StructKeyExists(arguments,"FeedID")
		AND	NOT StructKeyExists(variables.RSSReader,"Scheduler")
	>
		<cfset variables.RSSReader.updateFeed(arguments.FeedID)>
	<cfelse>
		<cfset variables.RSSReader.updateFeeds(false)>
	</cfif>
	
	<cfreturn getRecords(argumentCollection=arguments)>
</cffunction>

</cfcomponent>