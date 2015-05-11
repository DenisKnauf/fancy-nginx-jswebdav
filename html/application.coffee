console ?= {}
console.log ?= ->

$.fn.breadcrumb = ->
	bc = $ @
	path = bc.text().split '/'
	bc.empty()
	path.shift()
	path.pop()
	bc.append " <a href='/'>/</a> "  if 0 < path.length
	ap = '/'
	for p in path[0..-1]
		ap = "#{ap}#{p}/"
		bc.append " <a href='#{ap}'>#{p}/</a> "
	#bc.append " #{path.slice -1}/"
	bc.buttonset()

$.fn.fancy = (obj = 'html') ->
	$t = $ @
	$o = $ obj
	f = $.cookie 'fancy'
	$t.button().on 'change', (e) ->
		e.preventDefault()
		ch = $t.is(':checked')
		$o.toggleClass 'fancy', ch
		$.cookie 'fancy', (if ch then '1' else '0'), path: '/'
		console.log 'fancy:', $.cookie('fancy'), ch
	console.log 'fancy?', f, $t.is(':checked')
	$t.click()  if $t.is(':checked') != ('1' == f)
	$o.toggleClass 'fancy', $t.is(':checked')

$.fn.icon = (($) ->
	root = (filename = null) ->
		$t = $ @
		filename ?= $t.attr( 'data-filename') ? $t.attr( 'href')
		type =
			if /\/$/.test filename
				'inode/directory'
			else
				ext = /\.([^.]*)$/.exec filename
				if ext
					ext = ext[1]
					root.mime_types[ext]
		type ?= 'unknown'
		icon = root.mime_type_icons[type]
		$img = $ '<img>'
		$img.attr 'src', "/.:-==-:./icons/mimetypes/#{icon}"
		$t.prepend $img

	root.mime_types = {}
	root.mime_type_icons = {}
	root
)(jQuery)

$.fn.iconify = (($) ->
	root = ->
		$tr = $ @
		$a = $tr.children('td:first-child').children 'a'
		href = $a.attr 'href'
		$a.icon()
		menu = $('<td>').appendTo $tr
		$('<a data-method="delete">&#x2716;</a>').appendTo(menu).on 'click', root.destroy
		# $('<a data-method="mark">&#x2714;</a>').appendTo(menu).on 'click', root.mark
		menu.buttonset().children('a').attr href: href
		@

	root.destroy = (e) ->
		$t = $ @
		e.preventDefault()
		deleted = (e) -> $t.parent().parent().remove()
		uri = $t.attr 'href'
		if confirm "Delete #{uri}?"
			$.ajax url: uri, method: 'delete', success: deleted
		false

	root.mark = (e) ->
		$t = $ @
		e.preventDefault()
		$t.parent().parent().toggleClass 'marked'
		false

	root
)(jQuery)

$ ->
	$.getJSON '/.:-==-:./mime-types.json', (data, textStatus, xhr) ->
		i = $.fn.icon
		i.mime_types = data.types
		i.mime_type_icons = data.icons
		i.mime_type_icons['inode/directory'] = 'inode-directory.png'
		i.mime_type_icons['unknown'] = 'unknown.png'
		$(a).iconify()  for a in $('#list tbody tr')
		@
$ -> $('#fancy-toggle').fancy()
$ -> $('#breadcrumb').appendTo('header').breadcrumb()
$ ->
	for tr in $('#list tr')
		$tr = $ tr
		t = $tr.children( 'td:nth-child(2)').text()
		$tr.addClass 'dir'  if '-' == t
	@

# for drop-events needed!
$ -> $.event.props.push "dataTransfer"

$.upload = (->
	root = (file) ->
		if root.window and root.window.opener
			uw = root.window
			if root.ready
				root.upload file
				return @
		else
			root.ready = false
			uw = root.window = window.open '', 'upload_dialog',
					'menubar=no,dependent=no,status=no,toolbar=no,location=no,width=480,height=320,top=64,left=64'
			if uw.location and -1 == uw.location.href.indexOf( '/.:-==-:./upload.html')
				uw.location.href = '/.:-==-:./upload.html'
			else
				root.ready = true
				root.upload file
				return @
		root.queue.push file
		uw.focus()

	root.upload = (file) ->
		uw = root.window
		uw.jQuery( uw.document).trigger 'upload', [file, window.location.pathname]

	root.queue = []
	root.loaded = (e) ->
		root.ready = true
		root file  while file = root.queue.pop()

	root.finished = (e) ->
		$('#menu').append( '<span>Dir was changed, reload to see changes!</span>')

	root.activate = ->
		$(document).on upload_window_ready: root.loaded, uploaded: root.finished
	root
)()
$ -> $.upload.activate()

$ ->
	drag = (e) ->
		console.log 'drag', e.type, e
		e.stopPropagation()
		e.preventDefault()
		$(document).toggleClass 'draghover', 'draghover' == e.type
		false
	drop = (e) ->
		drag e
		files = e.target.files || e.dataTransfer.files
		console.log 'droped', files
		$.upload file  for file in files
	$('#upload-file').on 'change', drop
	$('body').on
		dragover: drag
		dragleaver: drag
		drop: drop
