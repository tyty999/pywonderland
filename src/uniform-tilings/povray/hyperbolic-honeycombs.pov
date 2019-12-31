/*
------------------------------------------------------
Main scene file for rendering 3D hyperbolic honeycombs 
------------------------------------------------------

by Zhao Liang 2019/12/25

*/
#version 3.7;

#include "colors.inc"

global_settings {
    assumed_gamma 2.2
    max_trace_level 10
}

background { SkyBlue }

// radius of a geodesic arc in hyperbolic metric
#declare hyper_radius = 0.04;
// number of spheres used in sphere_sweep
#declare num_segments = 30;

#declare edge_finish = finish {
  ambient 0.5
  diffuse 0.5
  specular .5
}

#declare edge_tex = texture {
  pigment { Pink }
  finish { edge_finish }
};

// hyperbolic distance to euclidean distance
#macro h2e(X)
    tanh(X/2)
#end

// euclidean distance to hyperbolic distance
#macro e2h(X)
    2*atanh(X)
#end

// get the euclidean radius of a sphere centered
// at a point p and has hyperbolic radius HR
#macro get_hyperbolic_rad(p, HR)
  #local R = vlength(p);
  #local r1 = h2e(e2h(R) + HR);
  #local r2 = h2e(e2h(R) - HR);
  (r1-r2)/2
#end

// inversion of a point p about the unit ball
#macro inversion(p)
  p / (p.x*p.x + p.y*p.y + p.z*p.z)
#end

// the hyperbolic geodesic arc connects two points p1, p2 in the
// unit ball, this arc has a constant hyperbolic radius hyper_radius
#macro HyperbolicEdge(p1, p2)
  #local cross = vlength(vcross(vnormalize(p1), vnormalize(p2)));
  // if p1 and p2 are colliner then connect them with
  // linearly interpolated spheres with constant hyperbolic radius
  #if (cross < 1e-6)
    sphere_sweep {
      cubic_spline
      num_segments + 1
      #for (k, 0, num_segments)
        #local q1 = (p1 + k/num_segments * (p2 - p1));
        q1, get_hyperbolic_rad(q1, hyper_radius)
      #end
      texture { edge_tex }
    }
  #else
    // else we find the center and radius of the geodesic arc
    // connnets p1 and p2, this requires three different points
    // on the circle. Since we know this circle is orthogonal
    // to the unit ball hence the inversion of p1 (or p2) is also
    // on the circle and can be used as the third point.
    #local p3 = inversion(p1);
    #local v1 = p2 - p1;
    #local v2 = p3 - p1;
    #local v11 = vdot(v1, v1);
    #local v22 = vdot(v2, v2);
    #local v12 = vdot(v1, v2);
    #local base = 0.5 / (v11 * v22 - v12 * v12);
    #local k1  = base * v22 * (v11 - v12);
    #local k2  = base * v11 * (v22 - v12);
    #local center = p1 + v1*k1 + v2*k2;
    #local rad = vlength(center - p1);
    sphere_sweep {
      cubic_spline
      num_segments + 1
      #for (k, 0, num_segments)
        #local q1 = (p1 + k/num_segments * (p2 - p1)) - center;
        #local q2 = vnormalize(q1) * rad + center;
        q2, get_hyperbolic_rad(q2, hyper_radius)
      #end
      texture { edge_tex }
    }
  #end
#end

union {
  #include "honeycomb-data.inc"
  #for (k, 0, num_vertices-1)
    #local q = vertices[k];
    sphere {
      q, get_hyperbolic_rad(q, hyper_radius*2.5)
      texture{
        pigment{ color Orange }
        finish {
          ambient 0.5
          diffuse 0.5
          specular 0.5 }
      }
    }
  #end
}

camera {
  location <0, 0, 0>
  look_at <0, 0, -1>
  up y
  right x*image_width/image_height
}

light_source {
  <0, 0, 0>
  color White
}
