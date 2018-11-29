.PHONY: put zip

put:
	rsync -vrt --delete --exclude=.git \
		--exclude=published \
		--exclude=doc \
		--exclude=data \
		--exclude=test \
		. /Volumes/Elder\ Scrolls\ Online/live/AddOns/LibPrice

zip:
	-rm -rf published/LibPrice published/LibPrice\ x.x.x.zip
	mkdir -p published/LibPrice
	cp -R LibPrice* published/LibPrice/
	cp -R readme.md published/LibPrice/
	mkdir -p published/LibPrice/doc
	cp -R doc/example.jpg published/LibPrice/doc/

	cd published; zip -r LibPrice\ x.x.x.zip LibPrice

	rm -rf published/LibPrice
