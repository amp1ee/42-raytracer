/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   button_drawer.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aminadzh <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2018/07/30 20:11:01 by aminadzh          #+#    #+#             */
/*   Updated: 2018/07/30 20:11:02 by aminadzh         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "rt.h"

void			draw_info_btns(t_sdl *sdl)
{
	SDL_Rect	dst;

	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[0], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[0], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[1], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[1], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[2], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[2], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[3], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[3], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[4], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[4], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[5], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	draw_info_btns2(sdl);
}

void			draw_info_btns2(t_sdl *sdl)
{
	SDL_Rect	dst;

	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[5], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[6], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[6], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[7], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[7], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[8], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[8], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[9], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[9], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[10], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	draw_info_btns3(sdl);
}

void			draw_info_btns3(t_sdl *sdl)
{
	SDL_Rect	dst;

	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[10], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 10, .y = sdl->ui.btn_pos_y[11], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[8], NULL, sdl->ui.message, &dst);
	dst = (SDL_Rect){.x = 31, .y = sdl->ui.btn_pos_y[11], .h = 16, .w = 15};
	SDL_BlitSurface(sdl->ui.menu_button[9], NULL, sdl->ui.message, &dst);
}
