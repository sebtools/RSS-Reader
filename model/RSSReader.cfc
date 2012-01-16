<cfcomponent display="RSS Reader" extends="com.sebtools.ProgramManager">

<cffunction name="init" access="public" returntype="any" output="no">
	<cfargument name="Manager" type="any" required="yes">
	<cfargument name="interval" type="string" default="daily">
	<cfargument name="Scheduler" type="any" required="no">
	
	<!--- Just here to verify interval is valid --->
	<cfset var mydate = DateAddInterval(arguments.interval)>
	
	<cfset Super.init(argumentCollection=arguments)>
	
	<cfreturn This>
</cffunction>

<cffunction name="DateAddInterval" returntype="date" output="no">
	<cfargument name="interval" type="string" required="true">
	<cfargument name="date" type="date" default="#now()#">
	
	<cfset var result = arguments.date>
	<cfset var timespans = "millisecond,second,minute,hour,day,week,month,quarter,year">
	<cfset var dateparts = "l,s,n,h,d,ww,m,q,yyyy">
	<cfset var num = 1>
	<cfset var timespan = "">
	<cfset var datepart = "">
	<cfset var ordinals = "first,second,third,fourth,fifth,sixth,seventh,eighth,ninth,tenth,eleventh,twelfth">
	<cfset var ordinal = "">
	<cfset var numbers = "one,two,three,four,five,six,seven,eight,nine,ten,eleven,twelve">
	<cfset var number = "">
	<cfset var weekdays = "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday">
	<cfset var weekday = "">
	<cfset var thisint = "">
	<cfset var sNums = 0>
	<cfset var isSubtraction = Left(Trim(arguments.interval),1) EQ "-">
	<cfset var sub = "">
	
	<cfif isSubtraction>
		<cfset arguments.interval = Trim(ReplaceNoCase(arguments.interval,"-","","ALL"))>
		<cfset sub = "-">
	</cfif>
	
	<cfif ListLen(arguments.interval) GT 1>
		<cfloop list="#arguments.interval#" index="thisint">
			<cfset result = DateAddInterval("#sub##thisint#",result)>
		</cfloop>
	<cfelse>
		<cfset arguments.interval = ReplaceNoCase(arguments.interval,"annually","yearly","ALL")>
		<cfset arguments.interval = ReReplaceNoCase(arguments.interval,"\b(\d+)(nd|rd|th)\b","\1","ALL")>
		<cfset sNums = ReFindNoCase("\b\d+\b",arguments.interval,1,true)>
		<!--- Figure out number --->
		<cfif ArrayLen(sNums.pos) AND sNums.pos[1] GT 0>
			<cfset num = Mid(arguments.interval,sNums.pos[1],sNums.len[1])>
		</cfif>
		<cfif ListFindNoCase(arguments.interval,"every"," ")>
			<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,"every"," ")," ")>
		</cfif>
		<cfloop list="#ordinals#" index="ordinal">
			<cfif ListFindNoCase(arguments.interval,ordinal," ")>
				<cfset num = num * ListFindNoCase(ordinals,ordinal)>
			</cfif>
		</cfloop>
		<cfloop list="#numbers#" index="number">
			<cfif ListFindNoCase(arguments.interval,number," ")>
				<cfset num = num * ListFindNoCase(numbers,number)>
			</cfif>
		</cfloop>
		<cfif ListFindNoCase(arguments.interval,"other"," ")>
			<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,"other"," ")," ")>
			<cfset num = num * 2>
		</cfif>
		<!--- Check if day of week is specified --->
		<cfloop list="#weekdays#" index="weekday">
			<cfif ListFindNoCase(arguments.interval,weekday," ")>
				<!--- Make sure the date given is on the day of week specified (subtract days as needed) --->
				<cfset arguments.date = DateAdd("d",- Abs( 7 - ListFindNoCase(weekdays,weekday) + DayOfWeek(arguments.date) ) MOD 7,arguments.date)>
				<cfset arguments.interval = ListDeleteAt(arguments.interval,ListFindNoCase(arguments.interval,weekday," ")," ")>
				<!--- Make sure we are adding weeks --->
				<cfset arguments.interval = ListAppend(arguments.interval,"week"," ")>
			</cfif> 
		</cfloop>
		
		<!--- Figure out timespan --->
		<cfset timespan = ListLast(arguments.interval," ")>
		
		<!--- Ditch ending "s" or "ly" --->
		<cfif Right(timespan,1) EQ "s">
			<cfset timespan = Left(timespan,Len(timespan)-1)>
		</cfif>
		<cfif Right(timespan,2) EQ "ly">
			<cfset timespan = Left(timespan,Len(timespan)-2)>
		</cfif>
		<cfif timespan EQ "dai">
			<cfset timespan = "day">
		</cfif>
		
		<cfif ListFindNoCase(timespans,timespan)>
			<cfset datepart = ListGetAt(dateparts,ListFindNoCase(timespans,timespan))>
		<cfelse>
			<cfthrow message="#timespan# is not a valid inteval measurement.">
		</cfif>
		
		<cfset result = DateAdd(datepart,"#sub##num#",arguments.date)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getComponentsList" access="public" returntype="string" output="false" hint="">
	<cfreturn "">
</cffunction>

<cffunction name="runScheduledTask" access="public" returntype="any" output="false" hint="">
	
	<cfset updateFeeds()>
	
</cffunction>

<cffunction name="updateFeed" access="public" returntype="any" output="false" hint="">
	<cfargument name="FeedID" type="numeric" required="yes">
	<cfargument name="force" type="boolean" default="false">
	
	<cfset var qFeed = variables.Feeds.getFeed(FeedID=arguments.FeedID,fieldlist="FeedURL,DateUpdated")>
	<cfset var qItems = 0>
	
	<cfif arguments.force OR DateAddInterval(variables.interval,qFeed.DateUpdated) GTE now()>
		<cflock name="#Hash('RSSReader_#arguments.FeedID#_#qFeed.FeedURL#')#" timeout="60">
			<!--- Extra check in case we got here after waiting on another lock to clear --->
			<cfif NOT arguments.force>
				<cfset qFeed = variables.Feeds.getFeed(FeedID=arguments.FeedID,fieldlist="FeedURL,DateUpdated")>
			</cfif>
			<cfif arguments.force OR DateAddInterval(variables.interval,qFeed.DateUpdated) GTE now()>
				<cfset qItems = getRSSItems(qFeed.FeedURL)>
				<cfloop query="qItems">
					<cfset variables.Items.addItem(
						FeedID=arguments.FeedID,
						Title=title,
						ItemDescription=description,
						link=link,
						quid=guid,
						PubDate=pubdate
					)>
				</cfloop>
				<cfset variables.Feeds.saveRecord(FeedID=arguments.FeedID,DateUpdated=now())>
			</cfif>
		</cflock>
	</cfif>
	
</cffunction>

<cffunction name="updateFeeds" access="public" returntype="any" output="false" hint="">
	
	<cfset var qFeeds = variables.Feeds.getFeeds(UpdatedBefore=DateAddInterval("-#arguments.interval#",now()),fieldlist="FeedID")>
	
	<cfloop query="qFeeds">
		<cfset updateFeed(FeedID)>
	</cfloop>
	
</cffunction>

<cffunction name="getRSSItems" access="private" returntype="query" output="no">
	<cfargument name="source" type="string" required="yes">
	
	<cfset var CFHTTP = 0>
	<cfset var xData = 0>
	<cfset var axItems = 0>
	<cfset var cols = "title,description,pubDate,link,guid">
	<cfset var qItems = QueryNew(cols)>
	<cfset var ii = 0>
	<cfset var col = "">
	<cfset var RSSText = "">
	
	<cfhttp url="#arguments.source#">
		<cfhttpparam type="Header" name="Accept-Encoding" value="deflate;q=0">
	</cfhttp>
	<cfset RSSText = REReplace(cfhttp.FileContent, "^[^<]*", "", "ALL")>
	
	<cfif NOT isXml(RSSText)>
		<cfhttp url="#arguments.source#">
			<cfhttpparam type="header" name="Accept-Encoding" value="*" />
		</cfhttp>
		<cfset RSSText = REReplace(cfhttp.FileContent, "^[^<]*", "", "ALL")>
	</cfif>
	
	<!---<cfif NOT isXml(RSSText)>
		<cfhttp url="#arguments.source#">
			<cfhttpparam type="header" name="Accept-Encoding" value="*" />
		</cfhttp>
		<cfset RSSText = REReplace(cfhttp.FileContent, "^[^<]*", "", "ALL")>
	</cfif>--->
	
	<cftry>
		<cfset xData = XmlParse(RSSText)>
		<cfset axItems = xData.rss.channel.item>
		
		<cfset QueryAddRow(qItems,ArrayLen(axItems))>
		<cfloop index="ii" from="1" to="#ArrayLen(axItems)#">
			<cfloop list="#cols#" index="col">
				<cfif StructKeyExists(axItems[ii],col)>
					<cfset QuerySetCell(qItems,col,HTMLEditFormat(axItems[ii][col].XmlText),ii)>
				</cfif>
			</cfloop>
		</cfloop>
	<cfcatch>
	</cfcatch>
	</cftry>
	
	<cfreturn qItems>
</cffunction>

<cffunction name="xml" access="public" output="yes">
<tables prefix="rss">
	<table entity="Feed" Specials="CreationDate,LastUpdatedDate,Sorter">
		<field name="FeedDescription" Label="Description" type="memo" />
		<field
			name="FeedURL"
			Label="Feed URL"
			type="text"
			Length="240"
			required="true"
			help="This is the URL of the RSS feed itself."
		/>
		<field name="SiteURL" Label="Site URL" type="text" Length="240" help="This is the URL for the site with which this feed is associated." />
		<filter name="UpdatedBefore" field="DateUpdated" operator="LTE" />
	</table>
	<table entity="Item" labelField="Title" Specials="CreationDate" sortField="PubDate" sortdir="DESC">
		<field fentity="Feed" />
		<field name="Title" Label="Title" type="text" Length="250" />
		<field name="guid" Label="guid" type="text" Length="240" required="true" />
		<field name="link" Label="link" type="text" Length="240" required="true" />
		<field name="ItemDescription" Label="Description" type="memo" />
		<field name="PubDate" Label="pubdate" type="date" />
	</table>
</tables>
</cffunction>

<cffunction name="loadScheduledTask" access="private" returntype="any" output="false" hint="">
	<cfif StructKeyExists(variables,"Scheduler")>
		<cfinvoke component="#variables.Scheduler#" method="setTask">
			<cfinvokeargument name="Name" value="#ListLast(sMe.name,'.')#">
			<cfinvokeargument name="ComponentPath" value="#sMe.name#">
			<cfinvokeargument name="Component" value="#This#">
			<cfinvokeargument name="MethodName" value="updateFeeds">
			<cfinvokeargument name="interval" value="daily">
			<cfinvokeargument name="hours" value="2,3">
		</cfinvoke>
	</cfif>
</cffunction>

<cffunction name="loadComponent" access="private" returntype="any" output="no" hint="I load a component into memory in this component.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var ext = getCustomExtension()>
	<cfset var extpath = "">
	
	<cfif NOT StructKeyExists(arguments,"path")>
		<cfset arguments.path = "#variables.me.path#.#arguments.name#">
	</cfif>
	
	<cfset extpath = "#getDirectoryFromPath(getCurrentTemplatePath())##arguments.path#_#ext#.cfc">
	
	<cfif Len(ext) AND FileExists(extpath)>
		<cfset arguments.path = "#arguments.path#_#ext#">
	</cfif>
	
	<cfset arguments["Manager"] = variables.Manager>
	<cfset arguments["Parent"] = This>
	<cfset arguments[variables.me.name] = This>
	
	<cfinvoke component="#arguments.path#" method="init" returnvariable="this.#name#" argumentCollection="#arguments#"></cfinvoke>
	
	<cfset variables[arguments.name] = This[arguments.name]>
	
</cffunction>

</cfcomponent>