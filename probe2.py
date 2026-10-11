import sys 
from pypdf import PdfReader 
r=PdfReader(sys.argv[1]) 
print('pages=',len(r.pages)) 
t=''.join([(p.extract_text() or '') for p in r.pages[:5]]) 
print('textlen5='+str(len(t))) 
