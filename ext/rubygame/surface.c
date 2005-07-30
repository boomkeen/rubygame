/*
	Rubygame -- Ruby code and bindings to SDL to facilitate game creation
	Copyright (C) 2004  John 'jacius' Croisant

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "rubygame.h"

/* Surface class */

/* 
 *  call-seq:
 *     Rubygame::Surface.new(size, depth=nil, flags=0)
 *
 *  Create and initialize a new Surface object. A display window must be set
 *  using Rubygame::Display.set_mode before creating a surface.
 *
 *  A Surface is a grid of image data which you blit (i.e. copy) onto other
 *  Surfaces. Since the Rubygame display is also a Surface (see the Screen 
 *  class), this method can be used to show images on the screen.
 *
 *  This function takes these arguments:
 *  - size::  requested surface size; an array of the form +[width, height]+.
 *  - depth:: color depth (bits per pixel) of the surface; defaults to the
 *            depth of the Rubygame display.
 *  - flags:: a bitwise OR'd ( | ) list of zero or more of the following flags
 *            (located in the Rubygame module, e.g. Rubygame::SWSURFACE).
 *            This argument may be omitted, in which case the Surface 
 *            will be a normal software surface (this is not necessarily a bad
 *            thing).
 *            - SWSURFACE::   (default) request a software surface.
 *            - HWSURFACE::   request a hardware-accelerated surface (using a 
 *                            graphics card), if available. Creates a software
 *                            surface if hardware surfaces are not available.
 *            - SRCCOLORKEY:: request a colorkeyed surface. #set_colorkey
 *                            will enable colorkey as needed. For a description
 *                            of colorkeys, see #set_colorkey.
 *            - SRCALPHA::    request an alpha channel. #set_alpha will
 *                            also enable alpha. as needed. For a description
 *                            of alpha, see #alpha.
 */
VALUE rbgm_surface_new(int argc, VALUE *argv, VALUE class)
{
	VALUE self;
	SDL_Surface *self_surf, *screen;
	SDL_PixelFormat *format;
	Uint32 flags, Rmask, Gmask, Bmask, Amask;
	int w, h, depth;
	
	/* Grab some format info from the screen surface */
	screen = SDL_GetVideoSurface();
	if( screen == NULL )
	{
		rb_raise(eSDLError,\
			"Could not get display surface to make new Surface: %s",\
			SDL_GetError());
	}
	format = screen->format;

	/* Prepare arguments for creating surface */
	/* Get width and height for new surface from argv[0] */
	Check_Type(argv[0],T_ARRAY);
	if(RARRAY(argv[0])->len >= 2)
	{
		w = NUM2INT(rb_ary_entry(argv[0],0));
		h = NUM2INT(rb_ary_entry(argv[0],1));
	}
	else
		rb_raise(rb_eArgError,"wrong size type (expected Array)");
	
	/* Get depth from arg or screen */
	/* if argv[1] exists, and is not nil or 0... */
	if(argc >= 2 && argv[1] != Qnil && NUM2INT(argv[1]) > 0)
	{
		/* then set depth from arg... */
		depth = NUM2INT(argv[1]);
	}
	else
	{
		/* else set depth from screen's depth. */
		depth = format->BitsPerPixel;
	}

	/* Get flags from arg, or set to 0*/
	/* if argv[2] exists, and is not nil... */
	if(argc >= 3 && argv[2] != Qnil)
	{
		/* then set flags from arg... */
		flags = NUM2UINT(argv[2]);
	}
	else
	{
		/* else set to 0. */
		flags = 0;
	}

	/* Get RGBA masks from screen */
	Rmask = format->Rmask;
	Gmask = format->Gmask;
	Bmask = format->Bmask;
	Amask = format->Amask;
		
	/* Create the new surface */

	self_surf = SDL_CreateRGBSurface(flags,w,h,depth,Rmask,Gmask,Bmask,Amask);
	if( self_surf == NULL )
	{
		rb_raise(eSDLError,"Could not create new surface: %s",SDL_GetError());
		return Qnil; /* should never get here */
	}

	/* Wrap the new surface in a crunchy candy VALUE shell */
	self = Data_Wrap_Struct( cSurface,0,SDL_FreeSurface,self_surf );
	/* The default initialize() does nothing, but could be overridden */
	rb_obj_call_init(self,argc,argv);
	return self;
}


VALUE rbgm_surface_initialize(int argc, VALUE *argv, VALUE self)
{
	return self;
}


/* Rubygame::Surface#width
 * Rubygame::Surface#w
 *
 * Return the width (in pixels) of the surface. 
 */
VALUE rbgm_surface_get_w(VALUE self)
{
	SDL_Surface *surf;
	Data_Get_Struct(self, SDL_Surface, surf);
	return INT2NUM(surf->w);
}

/* Rubygame::Surface#height
 * Rubygame::Surface#h
 *
 * Return the height (in pixels) of the surface. 
 */
VALUE rbgm_surface_get_h(VALUE self)
{
	SDL_Surface *surf;
	Data_Get_Struct(self, SDL_Surface, surf);
	return INT2NUM(surf->h);
}

/* Rubygame::Surface#size
 *
 * Return the surface's width and height (in pixels) in an Array.
 */
VALUE rbgm_surface_get_size(VALUE self)
{
	SDL_Surface *surf;
	Data_Get_Struct(self, SDL_Surface, surf);
	return rb_ary_new3( 2, INT2NUM(surf->w), INT2NUM(surf->h) );
}

/* Rubygame::Surface#depth
 *
 * Return the color depth (in bits per pixel) of the surface.
 */
VALUE rbgm_surface_get_depth(VALUE self)
{
	SDL_Surface *surf;
	Data_Get_Struct(self, SDL_Surface, surf);
	return INT2NUM(surf->format->BitsPerPixel);
}

/* Rubygame::Surface#flags
 *
 * Return any flags the surface was initialized with.
 */
VALUE rbgm_surface_get_flags(VALUE self)
{
	SDL_Surface *surf;
	Data_Get_Struct(self, SDL_Surface, surf);
	return INT2NUM(surf->flags);
}

/* Rubygame::Surface#masks
 *
 * Return the color masks +[r,g,b,a]+ of the surface. Almost everyone will
 * not need to use this function. Color masks are used to separate an
 * integer representation of a color into its seperate channels.
 */
VALUE rbgm_surface_get_masks(VALUE self)
{
	SDL_Surface *surf;
	SDL_PixelFormat *format;

	Data_Get_Struct(self, SDL_Surface, surf);
	format = surf->format;
	return rb_ary_new3(4,\
		INT2NUM(format->Rmask),\
		INT2NUM(format->Gmask),\
		INT2NUM(format->Bmask),\
		INT2NUM(format->Amask));
}

/* Rubygame::Surface#alpha
 *
 * Return the per-surface alpha (opacity; non-transparency) of the surface.
 * It can range from 0 (full transparent) to 255 (full opaque).
 */
VALUE rbgm_surface_get_alpha(VALUE self)
{
	SDL_Surface *surf;
	Data_Get_Struct(self, SDL_Surface, surf);
	return INT2NUM(surf->format->alpha);
}

/* Rubygame::Surface#set_alpha(alpha, flags=Rubygame::SRC_ALPHA)
 *
 * Set the per-surface alpha (opacity; non-transparency) of the surface.
 *
 * This function takes these arguments:
 * - alpha:: requested opacity of the surface. Alpha must be from 0 
 *           (fully transparent) to 255 (fully opaque).
 * - flags:: +0+ or Rubygame::SRC_ALPHA (default). Most people will want the
 *           default, in which case this argument can be omitted. For advanced
 *           users: this flag affects the surface as described in the docs for
 *           the SDL C function, SDL_SetAlpha.
 */
VALUE rbgm_surface_set_alpha(int argc, VALUE *argv, VALUE self)
{
	SDL_Surface *surf;
	Uint8 alpha;
	Uint32 flags = SDL_SRCALPHA;

	switch(argc)
	{
		case 2: flags = NUM2INT(argv[1]);
			/* no break */
		case 1:;
			int temp;
			temp = NUM2INT(argv[0]);
			if(temp<0) alpha = 0;
			else if(temp>255) alpha = 255;
			else alpha = (Uint8) temp;
			break;
		default:
			rb_raise(rb_eArgError,\
				"Wrong number of args to set mode (%d for 1)",argc);
	}

	Data_Get_Struct(self,SDL_Surface,surf);
	if(SDL_SetAlpha(surf,flags,alpha)!=0)
		rb_raise(eSDLError,"%s",SDL_GetError());
	return self;
}

/*
 *  call-seq:
 *     Rubygame::Surface#colorkey
 *
 *  Return the colorkey of the surface in the form +[r,g,b]+ (or +nil+ if there
 *  is no key). The colorkey of a surface is the exact color which will be
 *  ignored when the surface is blitted, effectively turning that color
 *  transparent. This is often used to make a blue (for example) background
 *  on an image seem transparent.
 */
VALUE rbgm_surface_get_colorkey( VALUE self )
{
	SDL_Surface *surf;
	Uint32 colorkey;
	Uint8 r,g,b;

	Data_Get_Struct(self, SDL_Surface, surf);
	colorkey = surf->format->colorkey;
	if((int *)colorkey == NULL)
		return Qnil;
	SDL_GetRGB(colorkey, surf->format, &r, &g, &b);
	return rb_ary_new3(3,INT2NUM(r),INT2NUM(g),INT2NUM(b));
}

/*
 *  call-seq:
 *     Rubygame::Surface#set_colorkey(color,flags=0)
 *
 *  Set the colorkey of the surface. See Surface#colorkey for a description
 *  of colorkeys.
 *
 *  This method takes these arguments:
 *  - color:: color to use as the key, in the form +[r,g,b]+. Can be +nil+ to
 *            un-set the colorkey.
 *  - flags:: +0+ or Rubygame::SRC_COLORKEY (default) or 
 *            Rubygame::SRC_COLORKEY|Rubygame::SDL_RLEACCEL. Most people will 
 *            want the default, in which case this argument can be omitted. For
 *            advanced users: this flag affects the surface as described in the
 *            docs for the SDL C function, SDL_SetColorkey.
 */
VALUE rbgm_surface_set_colorkey( int argc, VALUE *argv, VALUE self)
{
	SDL_Surface *surf;
	Uint32 color;
	Uint32 flag;
	Uint8 r,g,b;

	Data_Get_Struct(self, SDL_Surface, surf);
	if(argv[0] == Qnil)
	{
		flag = 0;
		color = 0;
	}
	else
	{
		if(argc > 1)
			flag = NUM2INT(argv[1]);
		else
			flag = SDL_SRCCOLORKEY;

		r = NUM2INT(rb_ary_entry(argv[0],0));
		g = NUM2INT(rb_ary_entry(argv[0],1));
		b = NUM2INT(rb_ary_entry(argv[0],2));
		//printf("RGB: %d,%d,%d  ",r,g,b);
		color = SDL_MapRGB(surf->format, r,g,b);
		//printf("colorkey: %d\n", color);
	}

	if(SDL_SetColorKey(surf,flag,color)!=0)
		rb_raise(eSDLError,"could not set colorkey: %s",SDL_GetError());
	return self;
}

static inline int max(int a, int b) {
  return a > b ? a : b;
}
static inline int min(int a, int b) {
  return a > b ? b : a;
}

/* 
 *  call-seq:
 *     Rubygame::Surface#blit(target,dest,source=nil)
 *
 *  Blit (copy & paste) all or part of the surface's image to another surface,
 *  at a given position. Returns a Rect representing the area of 
 *  +target+ which was affected by the blit.
 *
 *  This method takes these arguments:
 *  - target:: the target Surface on which to paste the image.
 *  - dest::   the coordinates of the top-left corner of the blit. Affects the
 *             area of +other+ the image data is /pasted/ over.
 *             Can also be a Rect or an Array larger than 2, but
 *             width and height will be ignored. 
 *  - source:: a Rect representing the area of the source surface to get data
 *             from. Affects where the image data is /copied/ from.
 *             Can also be an Array of no less than 4 values. 
 */
VALUE rbgm_surface_blit(int argc, VALUE *argv, VALUE self)
{
	if(argc < 2 || argc > 3)
		rb_raise( rb_eArgError,"Wrong number of arguments to blit (%d for 2)",argc);

	int left, top, right, bottom;
	int blit_x,blit_y,blit_w,blit_h;
	//int dest_x,dest_y,dest_w,dest_h;
	int src_x,src_y,src_w,src_h;
	VALUE returnrect;
	SDL_Surface *src, *dest;
	SDL_Rect *src_rect, *blit_rect;
	Data_Get_Struct(self, SDL_Surface, src);
	Data_Get_Struct(argv[0], SDL_Surface, dest);

	blit_x = NUM2INT(rb_ary_entry(argv[1],0));
	blit_y = NUM2INT(rb_ary_entry(argv[1],1));

	/* did we get a src_rect argument or not? */
	if(argc>2 && argv[2]!=Qnil)
	{
		/* it might be good to check that it's actually a rect */
		src_x = NUM2INT(rb_ary_entry(argv[2],0));
		src_y = NUM2INT(rb_ary_entry(argv[2],1));
		src_w = NUM2INT(rb_ary_entry(argv[2],2));
		src_h = NUM2INT(rb_ary_entry(argv[2],3));
	}
	else
	{
		src_x = 0;
		src_y = 0;
		src_w = src->w;
		src_h = src->h;
	}
	src_rect = make_rect( src_x, src_y, src_w, src_h );

	/* experimental (broken) rectangle cropping code */
	/* crop if it went off left/top/right/bottom */
	//left = max(blit_x,0);
	//top = max(blit_y,0);
	//right = min(blit_x+src_w,dest->w);
	//bottom = min(blit_y+src_h,dest->h);

	left = blit_x;
	top = blit_y;
	right = blit_x+src_w;
	bottom = blit_y+src_h;
		
	//blit_w = min(blit_x+blit_w,dest->w) - max(blit_x,0);
	//blit_h = min(blit_y+blit_h,dest->h) - max(blit_y,0);
	blit_w = right - left;
	blit_h = bottom - top;
	
	blit_rect = make_rect( left, top, blit_w, blit_h );

	SDL_BlitSurface(src,src_rect,dest,blit_rect);

	returnrect = rb_funcall(cRect,rb_intern("new"),4,
		INT2NUM(left),INT2NUM(top),\
		INT2NUM(blit_w),INT2NUM(blit_h));

	free(blit_rect);
	free(src_rect);
	return returnrect;
}

/* 
 *  call-seq:
 *     Rubygame::Surface#fill(color,rect=nil)
 *
 *  Fill all or part of a Surface with a color.
 *
 *  This method takes these arguments:
 *  - color:: color to fill with, in the form +[r,g,b]+ or +[r,g,b,a]+ (for
 *            partially transparent fills).
 *  - rect::  a Rubygame::Rect representing the area of the surface to fill
 *            with color. Omit to fill the entire surface.
 */
VALUE rbgm_surface_fill( int argc, VALUE *argv, VALUE self )
{
	SDL_Surface *surf;
	SDL_Rect *rect;
	Uint32 color;
	Uint8 r,g,b,a;

	Data_Get_Struct(self, SDL_Surface, surf);

	if(argc < 1)
	{
		rb_raise(rb_eArgError,"wrong number of arguments (%d for 1 or 2)",argc);
	}

	r = FIX2UINT(rb_ary_entry(argv[0],0));
	g = FIX2UINT(rb_ary_entry(argv[0],1));
	b = FIX2UINT(rb_ary_entry(argv[0],2));
	/* if the array is larger than [R,G,B], it should be [R,G,B,A] */
	if(RARRAY(argv[0])->len > 3)
	{
		a = FIX2UINT(rb_ary_entry(argv[0],3));
		color = SDL_MapRGBA(surf->format, r,g,b,a);
	}
	else
	{
		color = SDL_MapRGB(surf->format, r,g,b);
	}

	switch(argc)
	{
		case 1: /* fill whole thing */
			SDL_FillRect(surf,NULL,color);
			break;
		case 2: /* fill a given rect */
			rect = make_rect(\
				NUM2INT(rb_ary_entry(argv[1],0)),\
				NUM2INT(rb_ary_entry(argv[1],1)),\
				NUM2INT(rb_ary_entry(argv[1],2)),\
				NUM2INT(rb_ary_entry(argv[1],3))\
			);
			SDL_FillRect(surf,rect,color);
			free(rect);
			break;
		default:
			rb_raise( rb_eArgError,"Wrong number of arguments to fill (%d for 1 or 2)",NUM2INT(argc));
			break;
	}
	return self;
}

/* 
 *  call-seq: 
 *     Rubygame::Surface#get_at(pos)
 *     Rubygame::Surface#get_at(x,y)
 *
 *  Return the color (+[r,g,b,a]+) of the pixel at the given coordinate. 
 *
 *  This method takes these argument:
 *  - pos:: the coordinate of the pixel to get the color of.
 *
 *  The coordinate can also be given as two arguments, separate +x+ and +y+
 *  positions.
 */
VALUE rbgm_surface_getat( int argc, VALUE *argv, VALUE self )
{
	SDL_Surface *surf;
	int x,y;
	int locked=0;
	Uint32 color;
	Uint8 *pixels, *pix;
	Uint8 r,g,b,a;

	Data_Get_Struct(self, SDL_Surface, surf);

	if(argc>2)
		rb_raise(rb_eArgError,"wrong number of arguments (%d for 1)",argc);

	if(argc==1)
	{
		x = NUM2INT(rb_ary_entry(argv[0],0));
		y = NUM2INT(rb_ary_entry(argv[0],1));
	}
	else
	{
		x = NUM2INT(argv[0]);
		y = NUM2INT(argv[1]);
	}

	if(x<0 || x>surf->w)
		rb_raise(rb_eIndexError,"x index out of bounds (%d, min 0, max %d)",\
			x,surf->w);
	if(y<0 || y>surf->h)
		rb_raise(rb_eIndexError,"y index out of bounds (%d, min 0, max %d)",\
			y,surf->h);

	/* lock surface */
	if(SDL_MUSTLOCK(surf))
	{
		if(SDL_LockSurface(surf)==0)
			locked += 1;
		else
			rb_raise(eSDLError,"could not lock surface: %s",SDL_GetError());
	}

/* borrowed from pygame */
	pixels = (Uint8 *) surf->pixels;

    switch(surf->format->BytesPerPixel)
    {
        case 1:
            color = (Uint32)*((Uint8 *)(pixels + y * surf->pitch) + x);
            break;
        case 2:
            color = (Uint32)*((Uint16 *)(pixels + y * surf->pitch) + x);
            break;
        case 3:
            pix = ((Uint8 *)(pixels + y * surf->pitch) + x * 3);
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
            color = (pix[0]) + (pix[1]<<8) + (pix[2]<<16);
#else
            color = (pix[2]) + (pix[1]<<8) + (pix[0]<<16);
#endif
            break;
        default: /*case 4:*/
            color = *((Uint32*)(pixels + y * surf->pitch) + x);
            break;
	}

/* end borrowed from pygame */

	/* recursively unlock surface*/
	while(locked>1)
	{
		SDL_UnlockSurface(surf);
		locked -= 1;
	}

	if((int *)color == NULL)
	{
		VALUE zero = INT2NUM(0);
		return rb_ary_new3(4,zero,zero,zero,zero);
	}

	SDL_GetRGBA(color, surf->format, &r, &g, &b, &a);
	return rb_ary_new3(4,INT2NUM(r),INT2NUM(g),INT2NUM(b),INT2NUM(a));
}

void Rubygame_Init_Surface()
{

#if 0
	/* Pretend to define Rubygame module, so RDoc knows about it: */
	mRubygame = rb_define_module("Rubygame");
#endif

	cSurface = rb_define_class_under(mRubygame,"Surface",rb_cObject);
	rb_define_singleton_method(cSurface,"new",rbgm_surface_new,-1);
	rb_define_method(cSurface,"initialize",rbgm_surface_initialize,-1);
	rb_define_method(cSurface,"w",rbgm_surface_get_w,0);
	rb_define_alias(cSurface,"width","w");
	rb_define_method(cSurface,"h",rbgm_surface_get_h,0);
	rb_define_alias(cSurface,"height","h");
	rb_define_method(cSurface,"size",rbgm_surface_get_size,0);
	rb_define_method(cSurface,"depth",rbgm_surface_get_depth,0);
	rb_define_method(cSurface,"flags",rbgm_surface_get_flags,0);
	rb_define_method(cSurface,"masks",rbgm_surface_get_masks,0);
	rb_define_method(cSurface,"alpha",rbgm_surface_get_alpha,0);
	rb_define_method(cSurface,"set_alpha",rbgm_surface_set_alpha,-1);
	rb_define_method(cSurface,"colorkey",rbgm_surface_get_colorkey,0);
	rb_define_method(cSurface,"set_colorkey",rbgm_surface_set_colorkey,-1);
	rb_define_method(cSurface,"blit",rbgm_surface_blit,-1);
	rb_define_method(cSurface,"fill",rbgm_surface_fill,-1);
	rb_define_method(cSurface,"get_at",rbgm_surface_getat,-1);
}
