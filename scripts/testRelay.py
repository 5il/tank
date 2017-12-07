import smtplib
import sys

if( len(sys.argv) < 2 ):
 print( "Usage: "+sys.argv[0]+" <smtp server>" )
 exit()

s = smtplib.SMTP( sys.argv[1] )
try:
 s.sendmail("test@testing.com", "herp@derp.com", "This is a test from the pentest team")
except Exception as e:
 if "Relay access denied" in str(e):
  print( "  Not an open relay\n" )
 else:
  print( "Error in testRelay: "+str(e) )

print( "  Appears to be an open relay\n" )

s.close()
