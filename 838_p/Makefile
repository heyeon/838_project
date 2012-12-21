all: report mybib.bib
	latex report
	bibtex report
	latex report
	latex report
	dvips -o report.ps report.dvi
	ps2pdf report.ps
