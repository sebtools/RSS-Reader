<cfcomponent output="false">
	
<cffunction name="config" access="public" returntype="void" output="no">
	<cfargument name="Config" type="any" required="yes">
	
</cffunction>

<cffunction name="components" access="public" returntype="string" output="yes">
<program name="RSS Reader" description="This is a generic RSS reader program.">
	<components>
		<component name="RSSReader" path="[path_component]model.RSSReader">
			<argument name="Manager" component="Manager" />
			<argument name="Scheduler" component="Scheduler" ifmissing="skiparg" />
		</component>
	</components>
</program>
</cffunction>

<cffunction name="links" access="public" returntype="string" output="yes">
<program>
	<link label="Feeds" url="feed-list.cfm" />
</program>
</cffunction>

</cfcomponent>