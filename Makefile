all: index.html

%.html: resume.md | css/
	pandoc --standalone \
		--from markdown+yaml_metadata_block+raw_attribute \
		--to html \
		-o $@ $<

%.pdf: %.html
	pandoc --standalone -t html -o $@ $<

clean:
	rm -f *.html *.pdf *.txt

.PHONY: all clean
