all: index.html resume.pdf resume.txt

%.html: resume.md css/*
	pandoc --standalone \
		--from markdown+yaml_metadata_block+raw_attribute \
		--to html \
		-o $@ $<

%.pdf: resume.md css/*
	pandoc --pdf-engine=weasyprint -o $@ $<

%.txt: resume.md
	pandoc -t plain -o $@ $<

clean:
	rm -f *.html *.pdf *.txt

.PHONY: all clean
