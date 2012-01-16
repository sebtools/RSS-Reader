<cfcomponent extends="com.sebtools.Records">

<cffunction name="saveFeed" access="public" returntype="numeric" output="no">
	
	<cfset var result = saveRecord(argumentCollection=arguments)>
	
	<cfset variables.RSSReader.updateFeed(result,true)>
	
	<cfreturn result>
</cffunction>

</cfcomponent>