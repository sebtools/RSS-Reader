<cf_PageController>

<cf_Template showTitle="true" head_css="ul.rss-items-list li {padding-bottom:10px;}">

<cf_sebForm>
	<cf_sebField name="FeedName">
	<cf_sebField name="FeedURL">
	<cf_sebField name="SiteURL">
	<cf_sebField type="Submit/Cancel/Delete">
</cf_sebForm>

<cfif Action IS "Edit" AND qItems.RecordCount>
	<h3>Feed Items</h3>
	<ul class="rss-items-list">
		<cfoutput query="qItems" maxrows="#maxrows#">
		<li><a href="#link#">#Title#</a> (#DateFormat(pubDate,"mmmm d, yyyy")#)</li>
		</cfoutput>
	</ul>
	<cfif maxrows LT qItems.RecordCount>
		<cfoutput>
			<p><a href="feed-edit.cfm?id=#URL.id#&more=true">Show All</a></p>
		</cfoutput>
	</cfif>
</cfif>

</cf_Template>