uViewer
====

<br/>A simple viewer for VB6 to show PDF/WPS/EPUB documents.
<br/>Written in ANSI-C, this library is also platform-independent, therefore, it's suitable for any case that we're able to call the C functions, for example, Java native interface.

<br/>For a demo project for `Visual Basic 6`, please check 'platform/vb6/demo'.

> To build:
<br/>&emsp;In Windows, you should have the MinGW installed, in addition, GNU make, gcc, python, sed 4.2 or greater are also required.
<br/>&emsp;Then, change the directory to the root of project.
<br/>&emsp;&emsp; * make
<br/>&emsp;&emsp; * make install
<br/>&emsp;If you want to debug the demo project in VB6 IDE, please set `VB6_INSTALL_PATH` variable as your installation path of VB, to which we will copy the dll files.

<br/>&emsp;There will be two font libraries in 'build' directory:
<br/>&emsp;&emsp; * One is called 'libuvfont', which contained some frequently-used fonts. Be careful that some them is copyright, see /resources/fonts/*/COPYING for details.
<br/>&emsp;&emsp; * Another, called 'libuvfont-tiny', is a lite version of the first one.
<br/>
<br/>&emsp;To register a font (load it into memory as a shared object), consider `uv_register_font()` api.

----
  
This project is based on `MuPDF` core.
<br/>  MuPDF is Copyright 2006-2015 Artifex Software, Inc.

<br/>  This program is free software: you can redistribute it and/or modify it under
<br/>  the terms of the GNU Affero General Public License as published by the Free
<br/>  Software Foundation, either version 3 of the License, or (at your option) any
<br/>  later version.

<br/>  This program is distributed in the hope that it will be useful, but WITHOUT ANY
<br/>  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
<br/>  PARTICULAR PURPOSE. See the GNU General Public License for more details.

<br/>  You should have received a copy of the GNU Affero General Public License along
<br/>  with this program. If not, see <http://www.gnu.org/licenses/>.

----

TODO:
> * Password authentication in document opening is not supported.
> * Form UI in document(such as InputBox, CheckBox ComboBox, etc.).
> * Show outline and other infomation of document.
> * Text selecting, searching and copying.
