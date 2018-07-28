/******************************************************************************/
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   1.cl                                               :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: mstorcha <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2018/06/12 14:28:30 by mstorcha          #+#    #+#             */
/*   Updated: 2018/06/12 14:28:33 by mstorcha         ###   ########.fr       */
/*                                                                            */
/******************************************************************************/

#include "rendering.h.cl"
#include "./opencl/intersections.cl"
#include "./opencl/effects.cl"

void	swap(float f, float s)
{
	float tmp = f;
	f = s;
	s = tmp;
}

int		return_int_color(float3 c)
{
	return ((int)c.x * 0x10000 + (int)c.y * 0x100 + (int)c.z);
}

float3		return_point_color(int c)
{
	float3 p;
	p.x = (c >> 16) & 255; // 255
	p.y = (c >> 8) & 255; // 122
	p.z = c & 255; // 15
	return p;
}

float	sum_color(float f, float s)
{
	float r;

	r = clamp(f + s, 0.0f, 255.0f);
	r = clamp(f + s, 0.0f, 255.0f);
	r = clamp(f + s, 0.0f, 255.0f);

	return r;
}

float3		rotate_ort(float3 point, float3 rot)
{
	float3 od;
	float3 dv;
	float3 tr;
	float3 rot_rad;

	rot_rad.x = rot.x * M_PI / 180.0f;
	rot_rad.y = rot.y * M_PI / 180.0f;
	rot_rad.z = rot.z * M_PI / 180.0f;
	od.x = point.x;
	od.y = point.y * cos(rot_rad.x) + point.z * sin(rot_rad.x);
	od.z = point.z * cos(rot_rad.x) - point.y * sin(rot_rad.x);
	dv.x = od.x * cos(rot_rad.y) - od.z * sin(rot_rad.y);
	dv.y = od.y;
	dv.z = od.z * cos(rot_rad.y) + od.x * sin(rot_rad.y);
	tr.x = dv.x * cos(rot_rad.z) + dv.y * sin(rot_rad.z);
	tr.y = dv.y * cos(rot_rad.z) - dv.x * sin(rot_rad.z);
	tr.z = dv.z;
	return tr;
}

t_closest		closest_fig(float3 O, float3 D,
			float min, float max, __global t_figure *figures, int o_n)
{
	t_figure ret;
	float closest = INFINITY;
	float2 tmp;
	for (int i = 0; i < o_n; i++)
	{
		if (figures[i].type == CYLINDER)
			tmp = IntersectRayCylinder(O, D, figures[i]);
		else if (figures[i].type == CONE)
			tmp = IntersectRayCone(O, D, figures[i]);
		else if (figures[i].type == PLANE)
			tmp = IntersectRayPlane(O, D, figures[i]);
		else if (figures[i].type == SPHERE)
			tmp = IntersectRaySphere(O, D, figures[i]);

		if (tmp.x >= min && tmp.x <= max && tmp.x < closest)
		{
			closest = tmp.x;
			ret = figures[i];
		}
		if (tmp.y >= min && tmp.y <= max && tmp.y < closest)
		{
			closest = tmp.y;
			ret = figures[i];
		}
	}
	return (t_closest){closest, ret};
}

float   compute_light(float3 P, float3 N, float3 V, float s, __global t_figure *figures,
                    __global t_figure *light, int o_n, int l_n)
{
    float koef = 0.1f;
    for (int i = 0; i < l_n; i++)
    {
        t_figure l = light[i];
        float3 Lp = {l.p.x, l.p.y, l.p.z};
        float3 L = Lp - P;
        //shadow
        t_closest clos = closest_fig(P, L, 0.001f, 0.99f, figures, o_n);
        float closest = INFINITY;
        closest = clos.closest;
        if (closest != INFINITY)
            continue;
        //difuse
        float n_dot_l = dot(N,L);
        if (n_dot_l > 0.0f)
            koef += l.angle * n_dot_l / (fast_length(N) * fast_length(L));
        //zerk
        if (s != -1.0f)
        {
            float3 R = N * 2.0f * n_dot_l - L;
            float r_dot_v = dot(R,V);
            if (r_dot_v > 0.0f)
                koef += l.angle*pow(r_dot_v / (fast_length(R) * fast_length(V)), s);
        }
    }
    return (koef > 1.0f) ? 1.0f : koef;
}

float3	ReflectRay(float3 R, float3 N)
{
	return 2.0f * N * dot(R, N) - R;
}

float3	RefractRay(float3 R, float3 N, float n1, float n2)
{
	float n = n1 / n2;
	float cosI = - dot(N, R);
	float sinT2 = n * n * (1.f - cosI * cosI);
	if (sinT2 > 1.f || sinT2 < -1.f)
		return (float3){ 0.f, 0.f, 0.f};
	float cosT = sqrt(1.f - sinT2);
	return n * R + (n * cosI - cosT) * N;
}

void 	fresnel(float3 R, float3 N, float n1, float n2, float *kr) 
{ 
	float ior = n1 / n2;
    float cosi = clamp((float)dot(R, N), -1.f, 1.f); 
    float etai = 1.f, etat = ior; 
    if (cosi > 0.f) 
    	swap(etai, etat);

    float sint = etai / etat * sqrt(max(0.f, 1.f - cosi * cosi));

    if (sint >= 1.f)
        *kr = 1.0f;
    else
    { 
        float cost = sqrtf(max(0.f, 1.f - sint * sint)); 
        cosi = fabsf(cosi); 
        float Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost)); 
        float Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost)); 
        *kr = (Rs * Rs + Rp * Rp) / 2.0f; 
    }
}

float3   compute_normal(t_figure figure, float3 D, float3 P)
{
	float3 N;
	
	if (figure.type == PLANE)
	{
		float3 d = {figure.d.x, figure.d.y, figure.d.z};
		if (dot(d,D) < 0.0f)
			N = fast_normalize(d);
		else 
		 	N = fast_normalize(-d);
	}
	else if (figure.type == CONE)
	{
		float3 d = {figure.d.x, figure.d.y, figure.d.z};
		float3 p = {figure.p.x, figure.p.y, figure.p.z};
		float3 T = d-p;
		T = T / fast_length(T);
		N = P - p;
		T = T * dot(N, T);
		N = N - T;
		N = fast_normalize(N);
	}
	else if (figure.type == SPHERE)
	{
		float3 p = {figure.p.x, figure.p.y, figure.p.z};
		N = P - p;
		N = N / fast_length(N);
	}
	else if (figure.type == CYLINDER)
	{
		float3 p = {figure.p.x, figure.p.y, figure.p.z};
		float3 d = {figure.d.x, figure.d.y, figure.d.z};
		N = P - p;
		float3 T = d - p;
		T = T / fast_length(T);
		T = T * dot(N, T);
		N = (N - T) / fast_length(N - T);
	}
	return N;
}
float3			calc_uv(float3 N, float3 P, t_figure obj)
{
	float3	U;
	float3	V;
	float3	ret = 0.0F;

	N = -N;
	ret.x = 0.5F + atan2pi(N.z, N.x) / 2.0f;
	if (obj.type == SPHERE)
		ret.y = 0.5F - asin(N.y) / M_PI;
	else if (obj.type == CYLINDER)
	{
		float H = fast_length(obj.d - obj.p);
		float h = fast_length(P - obj.p);
		ret.y = sqrt(h * h - obj.radius * obj.radius) / H / 2.0f * obj.radius;
	}
	else if (obj.type == CONE)
	{
		float H = fast_length(obj.d - obj.p);
		float h = fast_length(P - obj.d);
		ret.y = -h / H;
	}
	else if (obj.type == PLANE)
	{
		if (N.y >= 0 && N.y <= 0.0003f)
			N.y = N.z;
		else if (N.x >= 0 && N.x <= 0.0003f)
			N.x = N.z;

		U = fast_normalize((float3){N.y, N.x, 0.0F});
		V = cross(N, U);

		ret.x = 1.0F - dot(U, P);
		ret.y = dot(V, P);
	}
	return (ret);
}

float3			get_obj_color(float3 NL, float3 P, t_figure obj,
							__global int3 *t_i, __global int *textures)
{
	int2			textures_info;
	float3			UV;
	int2			tex_pos;
	__global int	*tex;
	float 			scale;
	int	tmp = 0;
	int i = -1;

	//for (int i = 0; i < 2; i++)
	//	printf("%d %d %d\n", t_i[i].x, t_i[i].y, t_i[i].z);

	while (t_i[++i].z != obj.index)
	{
		//printf("%d %d %d\n", t_i[i].x, t_i[i].y, t_i[i].z);
		tmp += t_i[i].x * t_i[i].y;
	}
	//printf("our\n");
	tex = textures + tmp;
	
	UV = calc_uv(NL, P, obj);
	UV = rotate_ort(UV, (float3){0,0,0});
	textures_info = (int2) {t_i[i].y, t_i[i].x};

	//if (obj.scale <= EPSILON)
	scale = 1.0F;

	tex_pos.x = (int)((UV.x) * scale * (float)textures_info.x) % textures_info.x;
	if (tex_pos.x < 0)
		tex_pos.x = textures_info.x + tex_pos.x;
	tex_pos.y = (int)((UV.y) * scale * (float)textures_info.y) % textures_info.y;
	if (tex_pos.y < 0)
		tex_pos.y = textures_info.y + tex_pos.y;
	tex_pos.y = textures_info.y - tex_pos.y - 1;
	return (return_point_color(tex[(tex_pos.y) * (textures_info.x) + (tex_pos.x)]));
}

float3 TraceRay(float3 O, float3 D, float min, float max, __global t_figure *figures,
					__global t_figure *light, int o_n, int l_n, __global int *textures, __global int3 *textures_sz)
{
	float3 hit_color;
	float3 P;
	float3 N;
	float3 local_c = (float3){0.0f,0.0f,0.0f};
	float closest = 0.0f;
	t_figure figure;
	float rfl_mask = 1.0f;
	float rfr_mask = 1.0f;
	int mat = 0;
	float3 NL;

	hit_color = (float3){0.0f, 0.0f, 0.0f};
	for (int i = 0;i < NUM_REFL;)
	{
		float c_l = 0.0f;
		t_closest clos = closest_fig(O, D, min, max, figures, o_n);
		closest = clos.closest;
		if (closest == INFINITY)
			//return (float3) {0, 0, 0};
			break ;
		figure = clos.figure;
		P = O + D * closest;
		N = compute_normal(figure, D, P);
		c_l = compute_light(P, N, -D, 20.0f, figures, light, o_n, l_n);

		if (figure.text)
		{
			//printf("%d\n", figure.index);
			NL = dot(N, D) > 0.0F ? N * (-1.0F) : N;
			local_c = get_obj_color(NL, P, figure, textures_sz, textures);
		}
		else
			local_c = figure.color;
		local_c *= c_l;


		mat = figure.matirial;
		if (mat == 0)
	 	{
			hit_color = hit_color + local_c * (rfl_mask * rfr_mask);
			break ;
	 	}
		else if (mat == 1)
		{
			D = ReflectRay(-D, N);
			O = P;
			hit_color = hit_color + local_c * ((1.0f - figure.rfl) * rfl_mask * rfr_mask);
			rfl_mask = rfl_mask * figure.rfl;
			min = 0.001f;
			i++;
		}/*
		else if (mat == 2)
		{	
			float kr;

			fresnel(D, N, 1.f, 2.f, &kr);
			if (kr < 1.f)
			{
				D = RefractRay(P, N, 1.f, 2.f);
				O = P;
				hit_color += local_c * (1.0f - figure.rfr) * rfr_mask * (1.f - kr);
				rfr_mask *= figure.rfr;
				min = 0.001f;
				i++;
				continue ;
			}
			D = ReflectRay(-D, N);
			O = P;
			hit_color += local_c * ((1.0f - figure.rfl) * rfl_mask * (kr));
			rfl_mask *= figure.rfl;
			min = 0.001f;
		}
		i++;*/
	}
	return hit_color;
}

void apply_effects(__global int *data, __global int *out, int type)
{
	int j = get_global_id(0);
	int i = get_global_id(1);
	float3 c;
	float3 a = return_point_color(data[j * 1200 + i]);
	if (type == 1)
	{
		c = e_grades_gray(a);
	}
	else if (type == 2)
	{
		c = e_sepia(a);
	}
	else if (type == 3)
	{
		c = e_negative(a);
	}
	else if (type == 4)
	{
		c = e_black_white(a);
	}
	out[j * 1200 + i] = return_int_color(c);
}

float fade(float t) { return t * t * t * (t * (t * 6 - 15) + 10); }

float lerp(float t, float a, float b) { return a + t * (b - a); }

float grad(int hash, float x, float y, float z)
{
	int h = hash & 15;                      // CONVERT LO 4 BITS OF HASH CODE
	float u = h<8 ? x : y,                 // INTO 12 GRADIENT DIRECTIONS.
	v = h<4 ? y : h==12||h==14 ? x : z;
	return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
}

float noise1(float x, float y, float z) {
	int p[512] = { 151,160,137,91,90,15,
   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
   190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
   88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
   77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
   102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
   135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
   5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
   223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
   129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
   251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
   49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,151,160,137,91,90,15,
   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
   190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
   88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
   77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
   102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
   135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
   5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
   223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
   129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
   251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
   49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
   };
      int X = (int)floor(x) & 255,                  // FIND UNIT CUBE THAT
          Y = (int)floor(y) & 255,                  // CONTAINS POINT.
          Z = (int)floor(z) & 255;
      x -= floor(x);                                // FIND RELATIVE X,Y,Z
      y -= floor(y);                                // OF POINT IN CUBE.
      z -= floor(z);
      float u = fade(x),                                // COMPUTE FADE CURVES
             v = fade(y),                                // FOR EACH OF X,Y,Z.
             w = fade(z);
      int A = p[X  ]+Y, AA = p[A]+Z, AB = p[A+1]+Z,      // HASH COORDINATES OF
          B = p[X+1]+Y, BA = p[B]+Z, BB = p[B+1]+Z;      // THE 8 CUBE CORNERS,

      return lerp(w, lerp(v, lerp(u, grad(p[AA  ], x  , y  , z   ),  // AND ADD
                                     grad(p[BA  ], x-1, y  , z   )), // BLENDED
                             lerp(u, grad(p[AB  ], x  , y-1, z   ),  // RESULTS
                                     grad(p[BB  ], x-1, y-1, z   ))),// FROM  8
                     lerp(v, lerp(u, grad(p[AA+1], x  , y  , z-1 ),  // CORNERS
                                     grad(p[BA+1], x-1, y  , z-1 )), // OF CUBE
                             lerp(u, grad(p[AB+1], x  , y-1, z-1 ),
                                     grad(p[BB+1], x-1, y-1, z-1 ))));
}

__kernel void create_disruption(__global int * data, float3 color, int type)
{
	int j = get_global_id(0);
	int i = get_global_id(1);

	float koef = 20.f;
	float dx = (float) j / 1200.0f;
    float dy = (float) i / 1200.0f;
    int frequency = 100;
    float noise = noise1((dx * koef) + koef , (dy * koef) + koef, koef);
    noise = (noise - 1) / 2;
    int b = (int)(noise * 0xFF);
    int g = b * 0x100;
    int r = b * 0x10000;
    int finalValue = r;
    data[j * 1200 + i] = finalValue;
}

__kernel void rendering(__global int * data, __global t_figure *figures,
					__global t_figure *light, t_figure cam,
					int l_n, int o_n, __global int *textures, __global int3 *textures_sz)
{
	int j = get_global_id(0);
	int i = get_global_id(1);

	float3 O = { cam.p.x, cam.p.y, cam.p.z };
	float3 D;
	D.x = ((float)i - (float)WIDTH / 2.0f) * 0.5f / (float)WIDTH;
	D.y = (-(float)j + (float)WIDTH / 2.0f) * 0.5f / (float)HEIGHT;
	D.z = 1.f; // vv from cam
	D = rotate_ort(D, cam.d);

	float3 c = TraceRay(O, D, 1.0F, INFINITY, figures, light, o_n, l_n, textures, textures_sz);
	
	//float3 new = e_black_white(c);
	data[j * 1200 + i] = return_int_color(c);
}


__kernel void find_figure(__global int *returnable,
							__global t_figure *figures,
							t_figure cam, int i, int j, int o_n)
{
	float d = 1;
	float3 O = { cam.p.x, cam.p.y, cam.p.z };
	float3 D;
	D.x = ((float)i - (float)WIDTH / 2.0f) * 0.5f / (float)WIDTH;
	D.y = (-(float)j + (float)WIDTH / 2.0f) * 0.5f / (float)HEIGHT;
	D.z = d;
	D = rotate_ort(D, cam.d);

	t_closest clos = closest_fig(O, D, 1.0F, INFINITY, figures, o_n);
	if (clos.closest == INFINITY)
		*returnable = -1;
	else
		*returnable = clos.figure.index;
}
