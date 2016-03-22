// Copyright (c) 2015, <Mathias Aboudou>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library geometry;
import 'dart:math';

class GeometryUtil{
  
}

/**
 * Compute intersections with a given line defined by (x0,y0);(x1,y1)
 */
class IntersectRayComputer{
  final epsilon=pow(10,-8);
  final num x0,y0,x1,y1;
  num dx,dy;
  num dd;
  
  /**
   * Initialize the computer with the segment
   */
  IntersectRayComputer(this.x0,this.y0,this.x1,this.y1)
  {
    dx=x1-x0;
    dy=y1-y0;
    
    dd=_dotProduct(dx, dy, dx, dy);
  }
  
  /**
   * Return true is the line intersect the polygon defined by the list of point
   */
  bool intersectAsLine(List<Point> points){
    bool ret=false;
    
    if(points!=null && points.length>1){
      Turn initTurn=_turnsPoint(points.first);
      //if the first point intersect its already over
      if(initTurn==Turn.STRAIGHT){
        ret=true;
      }
      //otherwise
      else{
        for(int i=1 ; points.length ; i++){
          Turn turn=_turnsPoint(points.elementAt(i));
          //if the turn is differente from the initial, there is an intersection !
          if(turn!=initTurn){
            ret=true;
            break;
          }
        }
      }
    }
    
    return ret;  
  }
  
  /**
   * Compute the kind of Intersection between the line from x0,y0 toward x1,y1 and
   *  the segment defined by a and b
   */
  Intersection intersectAsRay(Point a, Point b){
    Intersection ret=Intersection.VOID;
    bool hit=false;
    //conversion to parametric equation : 
    // [a b] is a + us where u in [0,1] q a point and s a vector
    // our ray is (x0,y0) + t(dx,dy) where t in [0, +inf] 
    num sx=b.x-a.x;
    num sy=b.y-a.y;
    
    //resolve intersection from lines
    //t = (a − (x0,y0)) × s / (d × s)
    //u = (a − (x0,y0)) × d / (d × s)
    
    num d_cross_s=_crossProduct(dx,dy,sx,sy);
    //if d and s not colinear
    if(d_cross_s!=0){
      double t=_crossProduct(a.x-x0, a.y-y0, sx, sy)/d_cross_s;
      double u=_crossProduct(a.x-x0, a.y-y0, dx, dy)/d_cross_s;
      
      hit=(t>=0.0-epsilon) && (u>=0.0-epsilon) && (u<1.0+epsilon);
      
      if(hit){
        if (u<epsilon){
          ret=Intersection.CORNER_0;
        }
        else if((u-1.0).abs()<epsilon){
          ret=Intersection.CORNER_1;
        }
        else{
          ret=Intersection.HIT;
        }
      }
    }
    //if d and s colinears means If r × s = 0 and (a − (x0,y0)) × d = 0
    else if(_crossProduct(a.x-x0, a.y-y0, dx, dy)==0){
      //either 0 ≤ (a − (x0,y0)) · d ≤ d · d 
      //or 0 ≤ ((x0,y0) − a) · s ≤ s · s, 
      //then the two lines are overlapping
      num exp1=_dotProduct(a.x-x0, a.y-y0, dx, dy);
      if(exp1>=0 ||exp1<=dd){
        ret=Intersection.HIT;
      }
      else{
        num exp2=_dotProduct(x0-a.x, y0-a.y, sx, sy);
        hit=(exp2>=0)&&(exp2<=_dotProduct(sx, sy, sx, sy));
        if(hit){
          ret=Intersection.HIT;
        }
      }
    }    
    return ret;
  }
  
  //cross product v × w is vx wy − vy wx
  num _crossProduct(num vx,num vy,num wx,num wy){
    return vx*wy-vy*wx;
  }
  
  //cross product v × w is vx wy − vy wx
  num _dotProduct(num vx,num vy,num wx,num wy){
    return vx*wx + vy*wy;
  }
  
  
  /**
   * Tells whether a given point is “left of” or “right of” the given directed line.
   */
  Turn _turns(double x, double y){
    double cross;
    cross = (dx)*(y-y0) - (x-x0)*(dy);//(x1-x0)*(y-y0) - (x-x0)*(y1-y0);
    return((cross>0.0) ? Turn.LEFT : ((cross==0.0) ? Turn.STRAIGHT : Turn.RIGHT));
  }
  
  /**
   * Tells whether a given point is “left of” or “right of” the given directed line.
   */
  Turn _turnsPoint(Point p){
    return _turns(p.x, p.y);
  }
  
}

/**
 * Private class representing the position of a point relatively to a line
 */
class Turn {
    static const RIGHT = const Turn._();
    static const STRAIGHT = const Turn._();
    static const LEFT = const Turn._();

    static get values => [RIGHT, STRAIGHT,LEFT];

    const Turn._();
  }

/**
 * Private class representing the intersection between a line and a segment
 * Corner_0 represent an intersection with the first point of the segment
 * Corner_0 represent an intersection with the last point of the segment
 * HIT represent an intersection with the segment that is not one of its extremity
 * VOID represent no intersection
 */
class Intersection {
    static const VOID = const Intersection._("VOID");
    static const HIT = const Intersection._("HIT");
    static const CORNER_0 = const Intersection._("CORNER_0");
    static const CORNER_1 = const Intersection._("CORNER_1");

    static get values => [VOID, HIT,CORNER_0,CORNER_1];

    const Intersection._(this.displayName);
    
    final String displayName;
    
    String toString(){
      return displayName;
    }
  }
