 /**
* @constructor
* @class A wrapper class that reacts to events from python process
*/

String.prototype.getWidth = function(fontSize)
{
    var span = document.getElementById("spWidth");
    if (span == null) {
        span = document.createElement("span");
        span.id = "spWidth";
        document.body.appendChild(span);
        span.style.visibility = "hidden";
        span.style.whiteSpace = "nowrap";
    }

    span.innerText = this;
    span.style.fontSize = fontSize + "px";
    return span.offsetWidth;
}

ProcessProgressSink = function (_appid, _procname) {
    var result, lastImg = '', infotainmentSource = 'infotainment',
        infotainmentCount = 0;
    var infotainmentCountMap = {
        '73e72ada57b7480280f7a6f4a289729f': { 'Deploy': 7 }
    };

    // Reset the infotainment count and source according to
    // specializations for product and process as defined in
    // the infotainment count map.
    if (_appid in infotainmentCountMap) {
        infotainmentCountMap = infotainmentCountMap[_appid];
        if (_procname in infotainmentCountMap) {
            infotainmentSource = _procname;
        }
        if (infotainmentSource in infotainmentCountMap) {
            infotainmentCount = infotainmentCountMap[infotainmentSource];
        }
    }

    function _bgurlfor(idx) {
        return 'res/' + infotainmentSource + '/' + _appid + '/' + idx + '.png';
    }

    this.utility = Utilities;

    this.complete = function () {
    };

    this.initbg = function()
    {
        this.utility.setBackground(_bgurlfor(0));
    };

    this.progress = function (step, description, step_total, step_percentage) {
        var floatVal = parseFloat(step_percentage);
        var intVal = parseInt(floatVal)
        $("#progressdescription").html(description);
        $("#progressbarlabel").html(parseInt(intVal) + "%");
        $("#progressbar").progressbar({
            value: intVal
        });

        if (infotainmentCount) {
            var imgId = Math.min(infotainmentCount - 1, Math.floor( infotainmentCount * (floatVal/100) ) );
            var thisImg = _bgurlfor(imgId);
            if (thisImg != lastImg) {
                buff = $('#backbuff');
                // Make sure the back-buffer has the right image set
                this.utility.preloadBackground(thisImg);
                var self = this;
                buff.fadeIn(1200, function() {
                    // Now that the back buffer is displayed, "swap"
                    self.utility.setBackground(thisImg);
                    buff.hide();
                    // Pre-load the next image now, to give it time.
                    self.utility.preloadBackground(_bgurlfor(imgId + 1));
                });
                lastImg = thisImg;
            }
        }
    };

    this.reporterror = function (summary, detail, isError) {
        result = null;
        Utilities.showErrorDialog(summary, detail).then(function (returnVal) {
            result = returnVal;
        });
    };

    this.promptuser = function(summary, detail, iserror /*unused*/) {
        result = null;
        Utilities.promptUser(summary, detail).then(function(returnVal) {
            result = returnVal;
        });
    }

    this.provideproxycreds = function (summary, message) {
        result = null;
        Utilities.loginDialog(summary, message).then(function (returnVal) {
            result = returnVal;
        });
    };

    this.abortuninstall = function (summary, detail) {
        result = null;
		// process summary string containing embed data before sending to showEmbeddedSurvey
		// delimited like so, title|val?OXID|val
		let listOfParams = summary.split("?").map(function(i){return i.split("|")});
		let params = {};
		listOfParams.forEach(function(pair) {
			params[pair[0]] = pair[1]
		});
        if ('73e72ada57b7480280f7a6f4a289729f' == _appid ) {
            Utilities.showEmbeddedSurvey(_appid, params)
				.then(function (returnVal) { result = returnVal });
        } else {
            Utilities.promptAbortUser(params.title, detail).then(function (returnVal) {
                result = returnVal;
            });
        }
    };

    this.uninstallsurvey = function(appid, root) {
        result = null;
        Utilities.showUninstallSurvey(appid, root).then(function(returnVal) {
            result = returnVal;
        })
    };

    this.getresult = function () {
        return result;
    };
};

ProcessProgressSink.create = function (appid, procname) {
    return new ProcessProgressSink(appid, procname);
};

function Utilities() { };

Utilities._convertToHtml = function(instr) {
    instr = instr.replace(/\n/g, '<br/>');
    return instr;
};

Utilities.loginDialog = function (summary, detail, uri) {
    var defer = $.Deferred();
    var dialogDiv = $(document.createElement('div'));
    var form = '<form id="proxyloginform" name="proxyloginform" method="post">' +
                detail +
                '<table>' +
                    '<tbody>' +
                        '<tr>' +
                            '<td>Username: </td>' +
                            '<td><input type="text" name="username" id="username" size="18"></td>' +
                        '</tr>' +
                        '<tr>' +
                            '<td>Password:</td>' +
                            '<td><input type="password" name="password" id="password" size="18"></td>' +
                        '</tr>' +
                    '</tbody>' +
               '</table>' +
               '</form>'
    dialogDiv.html(form);
    dialogDiv.dialog({
        dialogClass: "noclose",
        modal: true,
        title: summary,
        buttons: {
            "Ok": function () {
                var form = $('#proxyloginform').serializeArray();
                var creds = new Object();
                creds.username = (form[0].value);
                creds.password = (form[1].value);
                defer.resolve(Utilities.toJSON(creds));
                $(this).dialog("close");
            },
            "Cancel": function () {
                defer.resolve("Cancel");
                $(this).dialog("close");
            }
        }
    });
    return defer.promise();
};

Utilities.promptUser = function(summary, detail) {
    var defer = $.Deferred();
	$(function () {
		// add json parse code here
		var strTitle, strBodyInfo, primaryBtn, secondaryBtn;
		try {
			var jsonObj = $.parseJSON(detail);
			strTitle = Utilities.strFromCharArr(BASE64.decoder(jsonObj.title));
			strBodyInfo = Utilities.strFromCharArr(BASE64.decoder(jsonObj.BodyInfo));
			primaryBtn = Utilities.strFromCharArr(BASE64.decoder(jsonObj.primaryBtn));
			secondaryBtn = Utilities.strFromCharArr(BASE64.decoder(jsonObj.secondaryBtn));
		}
		catch (err)
		{
			// set default message error here
			primaryBtn = 'Yes';
			secondaryBtn = 'No';
			strTitle = 'Latest version already installed';
			strBodyInfo = 'You already have the latest version of Fusion 360 installed on this system. Would you like to start Fusion 360?';
		}

		// set value to div
		var divTitle = $('.query-title');
		divTitle.html(strTitle);

		var divQueryBody = $('.query-body');
		divQueryBody.html(Utilities._convertToHtml(strBodyInfo));

		$('#btnYes').val(primaryBtn);
		$('#btnNo').val(secondaryBtn);

		$('.body-mask').fadeIn(100);   //show div theme-popover-mask
		$('.hide-query-msg').slideDown(200); //show div dialog

		// adjust the header height if necessary
		Utilities.adjustHeaderHeight(strTitle, 22);

		var pdRightCol1 = 8, pdRightCol2 = 34;
		var priBtnWidth = $("#btnYes").outerWidth();
		var secBtnWidth = $("#btnNo").outerWidth();
		var totalWidth = $(".hide-query-msg").width();
		var paddingLeft = totalWidth - secBtnWidth - priBtnWidth - pdRightCol1 - pdRightCol2;
		$(".div-bt-col1").css({"paddingLeft": paddingLeft});

		$('.dlg-titlebar .close').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-query-msg').slideUp(200);

			defer.resolve("No");
			return defer.promise();
		})
		$('#btnNo').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-query-msg').slideUp(200);

			defer.resolve("No");
			return defer.promise();
		})
		$('#btnYes').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-query-msg').slideUp(200);

			defer.resolve("Yes");
			return defer.promise();
		})

		$('.dlg-titlebar').mousedown(function (event) {
			var isMove = true;
			var abs_x = event.pageX - $('div.hide-query-msg').offset().left;
			var abs_y = event.pageY - $('div.hide-query-msg').offset().top;

			$(document).mousemove(function (event) {
				if (isMove) {
					var obj = $('div.hide-query-msg');
					obj.css({'left':event.pageX - abs_x, 'top':event.pageY - abs_y});
				}
			}).mouseup(function () {
				isMove = false;
			});
		});
	});

	return defer.promise();
};

Utilities.promptAbortUser = function(summary, detail) {
    var defer = $.Deferred();
	$(function () {
		var strTitle, strBodyInfo, primaryBtn, secondaryBtn;
		primaryBtn = 'Yes';
		secondaryBtn = 'No';
		if (!summary || summary == ""){
			strTitle = "Proceed With Uninstall";
		}
		else {
			strTitle = summary;
		}

		if (!detail || detail == ""){
			strBodyInfo = "You have chosen to uninstall the application. Continue?";
		}
		else {
			strBodyInfo = detail;
		}

		// set value to div
		var divTitle = $('.query-title');
		divTitle.html(strTitle);

		var divQueryBody = $('.query-body');
		divQueryBody.html(Utilities._convertToHtml(strBodyInfo));

		$('#btnYes').val(primaryBtn);
		$('#btnNo').val(secondaryBtn);

		$('.body-mask').fadeIn(100);   //show div theme-popover-mask
		$('.hide-query-msg').slideDown(200); //show div dialog

		// adjust the header height if necessary
		Utilities.adjustHeaderHeight(strTitle, 22);

		var pdRightCol1 = 8, pdRightCol2 = 34;
		var priBtnWidth = $("#btnYes").outerWidth();
		var secBtnWidth = $("#btnNo").outerWidth();
		var totalWidth = $(".hide-query-msg").width();
		var paddingLeft = totalWidth - secBtnWidth - priBtnWidth - pdRightCol1 - pdRightCol2;
		$(".div-bt-col1").css({"paddingLeft": paddingLeft});

		$('.dlg-titlebar .close').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-query-msg').slideUp(200);

			defer.resolve("No");
			return defer.promise();
		})
		$('#btnNo').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-query-msg').slideUp(200);

			defer.resolve("No");
			return defer.promise();
		})
		$('#btnYes').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-query-msg').slideUp(200);

			defer.resolve("Yes");
			return defer.promise();
		})

		$('.dlg-titlebar').mousedown(function (event) {
			var isMove = true;
			var abs_x = event.pageX - $('div.hide-query-msg').offset().left;
			var abs_y = event.pageY - $('div.hide-query-msg').offset().top;

			$(document).mousemove(function (event) {
				if (isMove) {
					var obj = $('div.hide-query-msg');
					obj.css({'left':event.pageX - abs_x, 'top':event.pageY - abs_y});
				}
			}).mouseup(function () {
				isMove = false;
			});
		});
	});

	return defer.promise();
};

Utilities.adjustHeaderHeight = function(strTitle, fontSize) {
    var strWide = strTitle.getWidth(fontSize);
	if (strWide > 382) {  //382 is the css width value for div class title-col
		$(".dlg-titlebar").css({"height": "108px"});
		$(".title-col").css({"height": "60px"});
		$(".div-close").css({"height": "48px"});

		return true;
	}

	return false;
};

Utilities.ReplaceAll = function(strOri, subStr, replaceStr){
	// to avoid infinite loop
	var bSubofReplace = replaceStr.indexOf(subStr) >= 0;

	while (strOri.indexOf(subStr) >= 0){
		strOri = strOri.replace(subStr, replaceStr);
		if (bSubofReplace)
			return strOri;
	}
	return strOri;
};

Utilities.strFromCharArr = function (cArr){
	var str = '';
	for(var i = 0, len = cArr.length ; i < len; ++i)
	{
		str += String.fromCharCode(cArr[i]);
	}

	return str;
};

Utilities.ReplaceAllMarks = function(strCol, markArr, repArr){
	if (markArr.length != repArr.length)
		throw new Error("Parsing data match error!");

	for(var i=0; i<markArr.length; i++) {
		strCol = Utilities.ReplaceAll(strCol, markArr[i], repArr[i]);
	}

	return strCol;
};

Utilities.showErrorDialog = function (summary, detail) {
    var defer = $.Deferred();
	$(function () {
		// add json parse code here
		var strTitle, strLogDir, strLogFile, strIssueLink, strCol_11, strCol_12, strCol_12_detail, strCol_21, strCol_22, strIssueReplaceLink, strForumLink, primaryBtn, secondaryBtn;
		var hasLogInfo = true;
		try {
			//var jsonObj = JSON.parse(detail);
			var jsonObj = $.parseJSON(detail);
			strTitle = Utilities.strFromCharArr(BASE64.decoder(jsonObj.title));
			strLogDir = Utilities.strFromCharArr(BASE64.decoder(jsonObj.LogDir));
			strLogFile = Utilities.strFromCharArr(BASE64.decoder(jsonObj.LogFile));
			strIssueLink = Utilities.strFromCharArr(BASE64.decoder(jsonObj.IssueLink));
			strCol_11 = Utilities.strFromCharArr(BASE64.decoder(jsonObj.Col_11));
			strCol_12 = Utilities.strFromCharArr(BASE64.decoder(jsonObj.Col_12));
			strCol_12_detail = Utilities.strFromCharArr(BASE64.decoder(jsonObj.Col_12_detail));
			strCol_21 = Utilities.strFromCharArr(BASE64.decoder(jsonObj.Col_21));
			strCol_22 = Utilities.strFromCharArr(BASE64.decoder(jsonObj.Col_22));
			primaryBtn = Utilities.strFromCharArr(BASE64.decoder(jsonObj.primaryBtn));
			secondaryBtn = Utilities.strFromCharArr(BASE64.decoder(jsonObj.secondaryBtn));

			strIssueReplaceLink = "<a href=\"javascript:void(0);\" onclick=\"window.external.callNative('1','";
			strIssueReplaceLink += strIssueLink;
			strIssueReplaceLink += "','')\">";

			strForumLink = "<a href=\"javascript:void(0);\" onclick=\"window.external.callNative('1','https://forums.autodesk.com/t5/fusion-360-support/bd-p/962','')\">Fusion 360 Support Forum";
			// do marks replace here

            var osSupportLink = "https://knowledge.autodesk.com/support/fusion-360/troubleshooting/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-Fusion-360.html"
            osSupportLink = "<a href=\"javascript:void(0);\" onclick=\"window.external.callNative('1' , '" + osSupportLink + "' , '')\">";

			var marksArr = new Array();
			var repArr = new Array();
			marksArr[0] = '<';  repArr[0] = '&lt;';
			marksArr[1] = '>';  repArr[1] = '&gt;';
			strCol_12_detail = Utilities.ReplaceAllMarks(strCol_12_detail, marksArr, repArr);
			strCol_12_detail = '<p class="RowErrDetail"><font class="err-font-color">' + strCol_12_detail + '</p></font>';

			marksArr = []; repArr = [];
			marksArr[0] = '<font2>';  repArr[0] = '<font class="href-link-color">';
			marksArr[1] = '</font2>';  repArr[1] = '</font>';
			marksArr[2] = '<a1>';  repArr[2] = strIssueReplaceLink;
			marksArr[3] = '</a1>';  repArr[3] = '</a>';
			marksArr[4] = '<a2>';  repArr[4] = strForumLink;
			marksArr[5] = '</a2>';  repArr[5] = '</a>';
            marksArr[6] = '<a3>'; repArr[6] = osSupportLink;
            marksArr[7] = '</a3>'; repArr[7] = '</a>';
			strCol_12 = Utilities.ReplaceAllMarks(strCol_12, marksArr, repArr);
			strCol_12 += strCol_12_detail;
			strCol_22 = Utilities.ReplaceAllMarks(strCol_22, marksArr, repArr);
		}
		catch (err)
		{
			if ((typeof(strLogDir) == "undefined") || (typeof(strLogFile) == "undefined"))
				hasLogInfo = false;

			primaryBtn = 'OK';
			secondaryBtn = 'Open Log File Location';
			strTitle = 'Problem installing Fusion 360';
			strCol_11 = "What's wrong?";
			strCol_12 = '<p>We are not sure what is causing the problem.</p>';
			strCol_12 += '<p><font class="err-font-color">';
			strCol_12 += err.message;
			strCol_12 += '</font></p>';

			strCol_21 = "What should I do?";
			strCol_22 = '<p>Get a screenshot of this dialog and collect the log files. Contact us through <a href="https://forums.autodesk.com/t5/fusion-360-support/bd-p/962"><font class="href-link-color">Fusion 360 Support Forum</font></a> for help.</p>';
		}

		// set value to div
		var divTitle = $('.error-title');
		divTitle.html(Utilities._convertToHtml(strTitle));

		var divCol_11 = $('.Col_11');
		divCol_11.html(strCol_11);

		var divCol_12 = $('.Col_12');
		divCol_12.html(Utilities._convertToHtml(strCol_12));

		var divCol_21 = $('.Col_21');
		divCol_21.html(strCol_21);

		var divCol_22 = $('.Col_22');
		divCol_22.html(Utilities._convertToHtml(strCol_22));

		$('#btnOK').val(primaryBtn);
		$('#btnDir').val(secondaryBtn);

		if (hasLogInfo == false)
		{
			$('.sec-btn').attr('disabled',"true");
		}
		else
		{
			$('.sec-btn').removeAttr('disabled');
		}

		$('.body-mask').fadeIn(100);   //show div theme-popover-mask
		$('.hide-error-msg').slideDown(200); //show div dialog

		// adjust the header height if necessary
		var bAdjust = Utilities.adjustHeaderHeight(strTitle, 22);

		// dynamic caculate for the height
		var maxHeightBody = 275, bottomPadding = 30;
		if (bAdjust) {
			maxHeightBody -= 30;
			$(".error-body").css({"max-height": maxHeightBody});
		}
		var divBodyHeight, hRow1, hRow2;//$(".error-body").height();
		divBodyHeight = $(".error-body").outerHeight();
		var hasCustomized = false;
		if (divBodyHeight < maxHeightBody) // if it is less than max-height
		{
			$(".Col_12").css({"paddingBottom":"0px"});
			$(".Col_22").css({"paddingBottom":"0px"});
			$(".bottom-error").css({"borderTop":"0px solid #D8D8D8"});
			hasCustomized = true;
		}
		else if (hasCustomized == false)
		{
			hRow1 = $(".Col_12").outerHeight();
			hRow2 = $(".Col_22").outerHeight();
			if (hRow1 + hRow2 < maxHeightBody + bottomPadding)
			{
				$(".Col_12").css({"paddingBottom":"0px"});
				$(".Col_22").css({"paddingBottom":"0px"});
				$(".bottom-error").css({"borderTop":"0px solid #D8D8D8"});
			}
		}

		// for dynamic button size process
		var pdRightCol1 = 8, pdRightCol2 = 34;
		var priBtnWidth = $("#btnOK").outerWidth();
		var secBtnWidth = $("#btnDir").outerWidth();
		var totalWidth = Math.round($(".hide-error-msg").width());
		var paddingLeft = totalWidth - secBtnWidth - priBtnWidth - pdRightCol1 - pdRightCol2;
		$(".div-bt-col1").css({"paddingLeft": paddingLeft});

		$('.dlg-titlebar .close').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-error-msg').slideUp(200);

			defer.resolve("OK");
			return defer.promise();
		})
		$('#btnDir').click(function(){
			window.external.callNative('3', strLogDir, strLogFile);
		})
		$('#btnOK').click(function(){
			$('.body-mask').fadeOut(100);
			$('.hide-error-msg').slideUp(200);

			defer.resolve("OK");
			return defer.promise();
		})

		$('.dlg-titlebar').mousedown(function (event) {
			var isMove = true;
			var abs_x = event.pageX - $('div.hide-error-msg').offset().left;
			var abs_y = event.pageY - $('div.hide-error-msg').offset().top;

			$(document).mousemove(function (event) {
				if (isMove) {
					var obj = $('div.hide-error-msg');
					obj.css({'left':event.pageX - abs_x, 'top':event.pageY - abs_y});
				}
			}).mouseup(function () {
				isMove = false;
			});
		});
	});

	return defer.promise();
};

 /**
  * Set the background image on the install UI
  * @param imgurl the url for the image relative to index.html
  */
Utilities.setBackground = function(imgurl) {
    $('#productlogo').css('background', 'url("' + imgurl + '")');
};

Utilities.preloadBackground = function(imgurl) {
    $('#backbuff').css('background', 'url("' + imgurl + '")');
};

 /**
  * Retrieves html content, wrapped in a jQuery object, from the given
  * url.  This should handle using the correct method given allowed operations
  * for the context (from web, vs from local)
  *
  * @param url A fully qualified url to the resource from which to pull html
  * @param callback a callback function that will be notified when network
  *     resources are available.  It should accept one argument which is
  *     the requested content
  * @param selector an optional string parameter detailing a jQuery selector
  *     which can be used to isolate specific content given all the available
  *     content in the requested resource.
  */
Utilities.jqFromUrl = function(url, callback, selector) {
    //var scrpt = document.createElement('script');
    //scrpt.src =  url + '.js';
    //scrpt.type = 'text/javascript';
    //var s = document.getElementsByTagName('script')[0];
    //s.parentNode.insertBefore(scrpt, s);

    if (0 === url.indexOf('file://')) {
        // If this is the case, the xhr object is not allowed to query the
        // file system, even if the loaded page is running from the file
        // system, so use our own method which embeds an invisible iframe.

        var ifrm = $('<iframe/>', {'style': 'display: none', 'src': url});
        ifrm.load(function() {
            var res = ifrm.contents();
            if (selector) {
                res = $(selector, res);
            }
            if (callback) {
                callback(res);
            }
        })
        $('body').append(ifrm);
    } else {
        // And yes, you cannot use the iframe method to get a network resource
        // when running from a page loaded from the filesystem, so in this
        // case, use the xhr-based functionality that comes with jQuery.

        if (selector) {
            url = url + ' ' + selector;
        }
        var div = $('<div/>').load(url, function() {
                if (callback) {
                    callback(div.contents());
                }
            }
        )
    }
};

Utilities.showUninstallSurvey = function(appid, basedir) {
    var defer = $.Deferred();

    var url = basedir + '/ui/' + appid + '/uninstallsurvey.html';
    var b = $('.productlogo');

    Utilities.jqFromUrl(url, function(res) {
        b.append(res);
        alert(res.attr('required-js'));

        $('#commitform').click(function() {
            //defer.resolve("Yes");
            uninstallsurvey.testit();
        });
        //$('#cancelform').click(function() {
        //   defer.resolve("No");
        //});
    }, '#main');

    return defer;
};

 Utilities.formArrayToQualtrics = function(inarray, form) {
     var result = {};
     function _toQualVal(initem) {
         var retval = initem.value;
         if ($('input[type!=text][name='+ initem.name + ']', form).length) {
             retval = {'Value': retval};

             // Check for write-in answers
             writeins = $('input[type=text][name=_'+ initem.name +'-'+
                     initem.value + ']', form)
             if (writeins.length) {
                retval.Text = writeins.prop('value');
             }
         }
         return retval;
     }
     var count = 0;
     for (var i = 0; i < inarray.length; i++) {
         var item = inarray[i];
         if (item.value) {
             if ('_' == item.name[0]) {
                 // do not put supporting, write-in fields in the json
                 continue;
             }
             count++;
             if (item.name in result) {
                 var val = result[item.name];
                 if (!$.isArray(val)) {
                     val = [val]
                 }
                 val.push(_toQualVal(item));
                 result[item.name] = val;

             } else {
                 result[item.name] = _toQualVal(item);
             }
         }
     }
     return [count, result];
 };

function _(str) { return str; }

Utilities.populateSurveyText = function(appid, form) {
    if ('73e72ada57b7480280f7a6f4a289729f' == appid) {
        var l10n = {}; //new Jed({} /* TODO: Pass actual localizations */)
        l10n._ = _ //l10n.gettext;
        form.find('h3').html(
			l10n._('We are sorry to see you go.'));
        form.find('#uninstall_cancel').html(l10n._('Cancel'));
        form.find('#uninstall_continue').html(
            l10n._('Uninstall'));
    }
}

/* temporary... hopefully */
Utilities.showEmbeddedSurvey = function(appid, params) {
    var defer = $.Deferred();
    var s = $('#' + appid + '-survey');
    Utilities.populateSurveyText(appid, s);
    s.show();

    $('#uninstall_cancel').click(function() {
        defer.resolve("No");
    });
    $('#uninstall_continue').click(function() {
		// UNINSTALLED=True is sent as embedded data to let qualtrics know
		// that the user followed through with the uninstall after seeing the survey
    	let posturl = 'https://new.qualtrics.com/SE?Q_PostResponse=TRUE&SurveyID=SV_2geW61H8OtY8r4x&UNINSTALLED=True' +
		'&QR=' + encodeURIComponent(JSON.stringify({"QID1":{"Value":"1"}})); // give dummy answer to send response
		// Encode embedded data into qualtrics url
		Object.keys(params).forEach(function(key){
			posturl += '&' + key + '=' + encodeURIComponent(params[key]);
		});
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.onreadystatechange = function() {
			if (xmlHttp.readyState === 4 && xmlHttp.status >= 400)
				alert('request generated an error: ' + xmlHttp.statusText);
		}
		xmlHttp.open("GET", posturl, true);
		xmlHttp.send();
		defer.resolve("Yes");
		s.fadeOut();
    });

    // Show sub-questions when questions are selected.
    $('.uninstall-survey form > ul > li > input:checkbox').click(
        function(event) {
            var targetParent = $(event.target).parent();
            targetParent.children('ul').slideToggle();

            // Clear any previously set values
            if (!event.target.checked) {
                targetParent.find('ul input').prop('checked', false)
                    .prop('value', '');
            }
        }
    );

    // Make sure an associated checkbox is selected when a user enters
    // data in a text input field
    $('.uninstall-survey form ul ul input:text').change(
        function(event) {
            $(event.target).parent().children('input:checkbox')
                .prop('checked', true);
        }
    )


    return defer;
};

// Poor man json stringifier... very incomplete,
// but for some reason JScript does not have built-in support for JSON
// ... and third party libs are too heavy for what we need.
Utilities.toJSON = function (obj) {
    var out = ['{'];
    var reg = /("|\\)/g;

    function _makeString(instr) {
        if (null === instr) {
            return "null";
        }
        if (typeof (instr) === "number") {
            return instr;
        }
        return '"' + instr.toString().replace(reg, "\\$1") + '"';
    }

    for (p in obj) {
        out = out.concat([
                    _makeString(p), ':',
                    _makeString(obj[p]), ','
                ]);
    }

    if (out[out.length - 1] === ',') {
        out.pop();
    }

    out.push('}');
    return out.join('');
};
