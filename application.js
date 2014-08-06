function addCommasToNumber(nStr) {
  nStr += '';
  x = nStr.split('.');
  x1 = x[0];
  x2 = x.length > 1 ? '.' + x[1] : '';
  var rgx = /(\d+)(\d{3})/;
  while (rgx.test(x1)) {
    x1 = x1.replace(rgx, '$1' + ',' + '$2');
  }
  return x1 + x2;
}

var sections = {
	EXPANDED      : "&#9660;",
	COLLAPSED     : "&#9658;",

  flip_section: function(el, section) {
    var arrow = Element.down(el, "small");

    if (Element.visible(section)) {
      arrow.update(this.COLLAPSED);
      Effect.toggle(section, 'slide', { duration: 0.25 });
    } else {
      arrow.update(this.EXPANDED);
      Effect.toggle(section, 'slide', { duration: 0.25 });
    }
  }
}

var watchlist = {
	lastTime : null,
	
	company: {
		startDeleteHover: function(id) {
			//Clear any hovers
			if(!this.lastTimer) return
			clearTimeout(this.lastTimer)
			//Toggle hover here
			Element.show('delete-' + id)
		},
		
		endDeleteHover: function(id) {
			command = 'Element.hide(\'delete-' + id + '\')'
			this.lastTimer = setTimeout(command, 600)
			//Element.hide('delete-' + id)
		}
	}
}

function setAdvancedSearchDefaults(){
	document.advsearchform.advsearchtext.value = "";
	document.advsearchform.advsearchtitle.value = "";
	document.advsearchform.segment.value = "";
	document.advsearchform.topic.value = "";
	document.advsearchform.author.value = "";
	document.basicsearchform.basicsearchbox.value = "";
	
	return false;
}

function updateUserFavoriteGroup(destDiv, action, groupId) {
	var favoriteGroupName = document.getElementById('user_favorite_group_name').value;
	if ( favoriteGroupName == "" ) {
		alert("Please enter a watch group name."); 
	}
	if(action == "ADD"){
		var pars = 'add=1&favoritegroupname=' + escape(favoriteGroupName);
	}
	else if (action == "DELETE"){
		var pars = 'delete=1&groupid=' + groupId + '&favoritegroupname=' + escape(favoriteGroupName);
	}
	var myAjax = new Ajax.Updater(destDiv, '/data/companies/update_watch_group', {method:'post',asynchronous:true, parameters: pars, evalScripts: true});
}

function updateUserFavorite(destDiv, action, gid, id) {
	if(action == "ADD"){
		var companyName = document.getElementById('company_name_' + gid).value;
		if ( companyName == "" ) {
			alert("Please enter a company name."); 
		}
		var pars = 'add=1&gid=' + escape(gid) + '&id=' + escape(id) + '&companyName=' + escape(companyName);
	}
	else if (action == "DELETE"){
		var pars = 'delete=1&gid=' + escape(gid) + '&id=' + escape(id);
	}
	var myAjax = new Ajax.Updater(destDiv, '/data/companies/update_watch_list', {method:'post',asynchronous:true, parameters: pars, evalScripts: true});
	
}


function sendResearchSuggestion() {
	var suggestion = document.getElementById('research_suggestion').value;
	if ( suggestion == "" ) {
		alert("Please enter a suggestion before sending it.");
	} else {
		var encodedSuggestion = encodeURIComponent(suggestion);
		var pars = 'suggestion=' + encodedSuggestion;
		var myAjax = new Ajax.Updater('suggestionresult', '/rate/suggest', {method:'post',
			asynchronous:false, parameters: pars, 
			onSuccess: function() {
			document.getElementById('research_suggestion').value = "";
			Element.toggle('suggesttopic'); }});
	}
}

function sendContactUsMessage() {
	var message = document.getElementById('contact_us').value;
	if ( message == "" ) {
		alert("Please enter a message before sending it.");
	} else {
		var encodedMessage = encodeURIComponent(message);
		var pars = 'message=' + encodedMessage;
		var myAjax = new Ajax.Updater('contactusresult', '/rate/suggest', {method:'post',
			asynchronous:false, parameters: pars, 
			onSuccess: function() {
			document.getElementById('contact_us').value = "";
			Element.toggle('contactus'); }});
	}
}

function updateEmployeeFilter(destDiv) {
    var myAjax2 = new Ajax.Updater(destDiv, '/say_searching', {method:'get',asynchronous:false});
	var pars = ''
	var filterSource = document.getElementById('employee_filter');
	var content = filterSource.value;
	if ( content != 0 ) {
		pars = 'filter=' + content
	}
    var myAjax = new Ajax.Updater(destDiv, '/employees/update_employee_list', {method:'get', asynchronous:true, parameters: pars});
}

function updateHeadlineFilter(destDiv, pagenum) {
    var myAjax2 = new Ajax.Updater(destDiv, '/say_searching', {method:'get',asynchronous:false});
	var pars = 'filter=1'
	var segmentSource = document.getElementById('segment');
	var categorySource = document.getElementById('category');
	var dateSource = document.getElementById('date');
	var companySource = document.getElementById('company_name');
	var content = segmentSource.value;
	
	if ( content != 0 ) {
		pars = pars + '&segment=' + content
	}
	content = categorySource.value;
	if ( content != 0 ) {
		pars = pars + '&category=' + content
	}
	content = dateSource.value;
	if ( content != '' ) {
		pars = pars + '&date=' + content;
	}
	content = companySource.value;
	if ( content != 0 ) {
		pars = pars + '&company_name=' + content;
	}
	pars = pars + '&page=' + pagenum;
    var myAjax = new Ajax.Updater(destDiv, '/headlines/update_headline_list', {method:'get',asynchronous:true, parameters: pars});
}

function updateWatchlist(destDiv) {
	var groupID = document.getElementById('watchgroupid').value;
	var pars = 'watchgroupid=' + groupID;
	var myAjax = new Ajax.Updater(destDiv, '/dashboard/update_watchlist', {method:'get',asynchronous:true, parameters: pars});
}

function updateReportFilter(destDiv, pagenum) {
	var source = document.getElementById(destDiv);
	source.innerHTML = "<p style=\"font-size: 1.5em\"><br/><br/>Searching...</p>";
	
	var pars = '';
	var segmentSource = document.getElementById('segment');
	var topicsSource = document.getElementById('topic');
	var authorsSource = document.getElementById('author');
	var priceFilterSource = document.getElementById('price_filter');
	var content = segmentSource.value;
	if ( content != 0 ) {
		pars = 'segment=' + content
	}
	if (topicsSource != null) {
		content = topicsSource.value;
		if ( content != 0 ) {
			if ( pars != '' ) {
				pars = pars + '&topic=' + content;
			} else {
				pars = 'topic=' + content;
			}
		}
	}
	content = authorsSource.value;
	if ( content != 0 ) {
		if ( pars != '' ) {
			pars = pars + '&author=' + content;
		} else {
			pars = 'author=' + content;
		}
	}
	content = url_query_param('price_filter');
	if ( content != null ) {
		if ( pars != '' ) {
			pars = pars + '&price_filter=' + content;
		} else {
			pars = 'price_filter=' + content;
		}
	}
    content = url_query_param('report_type');
    if ( content != null ) {
        if ( pars != '' ) {
            pars = pars + '&report_type=' + content;
        } else {
            pars = 'report_type=' + content;
        }
    }
	if ( pars != '' ) {
		pars = pars + '&page=' + pagenum;
	} else {
		pars = 'page=' + pagenum;
	}
    var myAjax = new Ajax.Updater(destDiv, '/store/update_product_list', {method:'get',asynchronous:true, parameters: pars});
}

var current_service = "";
function toggleServices (service_id) {
    if (current_service == "") {
        current_service = "1";
    }
    Element.hide("service-desc-" + current_service);
    current_service = service_id;
    Effect.Appear("service-desc-" + service_id);
    return false;
}

var current_industry = "";
function toggleIndustry (industry_id) {
    if (current_industry == "") {
        current_industry = "1";
    }
    Element.hide("industry-desc-" + current_industry);
    current_industry = industry_id;
	if (/Safari/.test(navigator.userAgent)) {
		// Safari appears to have problem with effects on floated elements.
		// Some notes online say this is fixed, but it's not in this situation - Nov 29 2006, DRB
		Element.show("industry-desc-" + current_industry);
	}
	else {
    	Effect.Appear("industry-desc-" + industry_id);
	}
    return false;
}

function team_tab(desiredtab) {
	// identify the <div> tag with id of 'teamnav', and then the first child node of that
	// which should be the <ul> tag of the tabbed team names.
	// beware whitespace between the <div> tag and the <ul> tag
	var tab;
	tab=document.getElementById('teamnav').firstChild;
	tab.id=desiredtab;
}

function event_tab(desiredtab) {
	// identify the <div> tag with id of 'eventnav', and then the first child node of that
	// which should be the <ul> tag of the tabbed team names.
	// beware whitespace between the <div> tag and the <ul> tag
	var tab;
	tab=document.getElementById('eventnav').firstChild;
	tab.id=desiredtab;
}

function url_query_param( name )
{
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var tmpURL = window.location.href;
  var results = regex.exec( tmpURL );
  if( results == null )
    return null;
  else
    return results[1];
}