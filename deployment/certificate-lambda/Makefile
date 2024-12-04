lambda: certificate-lambda.zip

build: requirements.txt
	mkdir -p build;
	pip install -r requirements.txt -t build/;

certificate-lambda.zip: build handler.py cert_template.pdf
	rm -f certificate-lambda.zip
	cp handler.py cert_template.pdf build/
	(cd build; zip ../certificate-lambda.zip -r .)

clean:
	rm -rf build/ certificate-lambda.zip
