(($)
	$.upload = (url, data = {}, type = 'POST', success, progress) ->
		progress_handler = (e) -> req.trigger 'progress'
		build =
			url: url
			data: data
			type: type
			xhr: ->
				xhr = $.ajaxSettings.xhr()
				xhr.upload.addEventListener 'progress', progress_handler, false  if xhr.upload
				xhr
		build.success = success  if success
		req = $.ajax build
		req.progress = (f) ->
			req.on 'progress', f  if f
		req.progress progress
		req

	$ ->
		$(document).on 'upload', (e, file, destdir) ->
			console.log 'e', e
			console.log 'ok, i will upload', file, destdir
			[li, req] = upload file, destdir
			$('#uploads).append li

		window.opener.$(window.opener.document).trigger 'upload_window_ready'

	upload = (file, destdir)
		li = $('<li>').addClass 'active'
		$('<span>').addClass('fn').text( "#{file.name}").appendTo li
		li.append ' &rArr; '
		$('<span>').addClass('dest').text( "#{destdir}").appendTo li
		li.append '<br/>'
		$('<progress>').attr( max: file.size, value: 0).appendTo li
		dest = destination file, destdir
		req = $.upload dest, file.name, file, 'PUT'
		req.progress (e) ->
			console.log new Date(), 'progress', e.loaded, e
			progress.attr value: e.loaded
		req.onload = (e) ->
			console.log new Date(), 'uploaded', e
			li.removeClass( 'active').addClass 'finished'
			progress.attr value: progress.attr( 'max')
			window.opener.$(window.opener.document).trigger 'uploaded', file
		[li, req]

	destination = (file, destdir) ->
		if '/' == destdir[destdir.length-1]
			"#{destdir}#{file.name}"
		else
			"#{destdir}/#{file.name}"

)(jQuery)
