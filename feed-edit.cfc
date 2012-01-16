<cfcomponent extends="_config.PageController" output="no">

<cfset loadExternalVars("Items",".RSSReader")>

<cffunction name="loadData" access="public" returntype="struct" output="no">
	
	<cfset var loc = StructNew()>
	<cfset var vars = Super.loadData()>
	
	<cfset default("URL.more","boolean",false)>
	
	<cfif vars.Action IS "Edit">
		<cfif URL.more>
			<cfset loc.maxrows = 0>
		<cfelse>
			<cfset loc.maxrows = 11>
		</cfif>
		<cfset vars.qItems = variables.Items.getItems(FeedID=URL.id,maxrows=loc.maxrows,fieldlist="ItemID,Title,pubDate,link")>
		<cfif URL.more>
			<cfset vars.maxrows = vars.qItems.RecordCount>
		<cfelse>
			<cfset vars.maxrows = 10>
		</cfif>
	</cfif>
	
	<cfreturn vars>
</cffunction>

</cfcomponent>