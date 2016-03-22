library hexvisibility;

import 'package:Hex/hex.dart';
import 'package:Hex/geometry.dart';
import 'package:logging/logging.dart';
import 'dart:math';

/**
 * Class implementing raycasting in an hex grid, from a fixed point. 
 */
class VisibilityAlgorithm{
  
  final AbstractVisibilityHex from;
  final Logger log = new Logger('VisibilityAlgorithm');
  
  
  VisibilityAlgorithm(this.from);
  
  /**
   * Change the visibility at true for all the visible Hex on the ray starting
   * at the <code>from</code> attribut toward the <code>to</code> parameter.
   */
  void visibleRayTo(Hex to, int distMax){
    
    //special case for diagonals
    HexDiagonal hexDiag=from.isDiagonal(to);
    
    log.fine("\n\nvisibleRayTo : from"+from.id+"\tto : "+to.id+"\tradius : "+distMax.toString()+"\tisDiag : "+(hexDiag==null?"NO":hexDiag.toString()));
    
    if(hexDiag!=null){
      //apply special algorithm for diagonals
      _visibleRayToDiag(hexDiag, distMax);
    }
    else{
      //initialize useful point for IntersectRayComputer
      Point fromCenter=from.relativeCenter;
      num toCenterx=to.relativeCenter.x;
      num toCentery=to.relativeCenter.y;
      
      //initialize IntersectRayComputer which compute intersection between lines and segments
      IntersectRayComputer irc= new IntersectRayComputer(fromCenter.x, fromCenter.y, toCenterx, toCentery);
      
      //Initial values
      AbstractVisibilityHex currentHex=from;//current hex the ray casted is in
      num hexSize=from.pixelSize;//hexes size (we assume all hexes are the same size)
      int startAltitude=from.altitude; //altitude of the starting point
      
      /*
       * The hexdirections from which the ray comes from. There can be two because
       * in case the ray intersect with a corner, it intersects with more than one hex.
       */
      List<HexDirection> prevDirs=[];
      
      HexDirection nextDir=null;//the direction in which we should look for the next hex intersecting the ray
      AbstractVisibilityHex nextHex=null;//the potential next hex wh should expect intersecting the ray.
      
      //set the visibility of the initial hex at true (its always visible)
      currentHex.visible=true;
      
      //boolean representing if the job casting the ray is done
      bool isDone=false;
         
      while(!isDone){
        
        log.finer("\nTest Intersection with hex : "+ currentHex.id);
        
        /*
         * Find the next direction in which the hex intersects the line.
         * For the edge of the current hex in all direction that the ray is not coming from, we test if
         * there is an intersection.
         */
        
        //intersection represent the kind of intersection we found.
        Intersection intersection=Intersection.VOID;
        
        //for the edges in all directions...
        nextDir =HexDirection.values.
          where((hd) => !prevDirs.contains(hd))// we don't consider the previous intersections
          .firstWhere((hd){//find the first edge that intersect our ray
            List<Point> edge=hd.getEdge(currentHex.relativeCenter, hexSize);
            intersection = irc.intersectAsRay(edge[0], edge[1]);//determine the intersection
            
            log.finer("Test Intersection with edge : "+ currentHex.id+" - "+hd.toString()+"\tresult : "+intersection.toString());
            
            //out when the intersection is hit or corner
            return (intersection!=Intersection.VOID);
        });

        /*
         * Compute the real next direction according to the intersection type. If the intersection was clear (HIT)
         * we just take the direction of the edge intersecting. But if we intersected a corner there is more
         * computing to choose in which next direction to go.
         * 
         * This method also update the previousDirs list.
         */
        nextDir=_findNextDir(irc,currentHex, nextDir,intersection, prevDirs);
        
        //we get the next hex in the computed direction
        nextHex=currentHex.getVisibilityHexInDir(nextDir);
        
        //some logs
        log.finer("Intersection in dir : "+ nextDir.toString());
        if(Logger.root.isLoggable(Level.FINER)){
          if(nextHex!=null){
            log.finer("Intersection with hex : "+ nextHex.id+"\t distTostart : "+from.distanceTo(nextHex).toString());
          }
          else{
            log.finer("Intersection with hex NULL");
          }
        }
        
        //if nextDir is null or ths distance too great, the ray is going out of the bounds, its over...
        if(nextHex==null || from.distanceTo(nextHex)>distMax){
          isDone=true;
        }
        //...otherwise we make the next hex visible and determine if it blocks the view
        else{
          nextHex.visible=true;
          
          bool blockView=!(startAltitude>=nextHex.altitude);//view blocked if hex altitude greater than starting points one
          
          //if the view is not blocked...
          if(!blockView){
            //prepare next step
            currentHex=nextHex;
            log.finer("Preepare next step: prevdir : "+ prevDirs.toString()+"\tnnew current hex : "+currentHex.id);
            
          }
          //if blocked view, it's over
          else{
            isDone=true;
          }
        }
      }
    }
  }
  
  /*
   * Compute the real next direction according to the intersection type. If the intersection was clear (HIT)
   * we just take the direction of the edge intersecting. But if we intersected a corner there is more
   * computing to choose in which next direction to go.
   * 
   * This method also update the previousDirs list.
   */
  HexDirection _findNextDir(IntersectRayComputer irc,AbstractVisibilityHex currentHex, HexDirection hexDir,Intersection intersection, List<HexDirection> prevDirs){
    HexDirection ret=null;
    
    switch(intersection){
      //clean intersection, we update the direction we are coming from
      //and return the direction.
      case Intersection.HIT:
        ret=hexDir;
        prevDirs.clear();
        prevDirs.add(hexDir.opposite());
        break;
        
      /*
       * if the intersection was hitting a corner, we have some more work finding which next direction 
       * is the one. Its either the suggested direction (hexDir) or the direction of the next edge, otherDir.
       * (Depending of the extremity of the edge that was hit, otheredge can be the next or previous edge) 
       */
      case Intersection.CORNER_0:
      case Intersection.CORNER_1:
        //compute the otherDirection according to the extremity of the edge that was hit
        HexDirection otherDir=(intersection==Intersection.CORNER_0)?hexDir.prev():hexDir.next();
        
        //if the other possible direction is one of the previous one. We can't select it so we return the other.
        if(prevDirs.contains(otherDir)){
          ret=hexDir;
        }
        
        /* if both directions are possible... some more work for us.
         * we choose the direction in which the next hex has the more "clean" intersection.
         * That because the ray can only go throught one of the next hexes, and thus, have a clean intersection with
         * it. The only case in which we have no clean intersection implies a diagonal ray, and this case is
         * already covered
         * 
         */
        else{
          ret=_dirWithMoreIntersection(irc,currentHex,hexDir, otherDir);
        }
        
        /*
         * Then we compute what the previous directions are.
         * They are both the direction we could come from for the two possible direction available.
         */
       
        HexDirection opposite=ret.opposite();//the opposite of the selected direction is always in prevDirs
        
        //if we chose hexDir...
        if(ret==hexDir){
          //case CORNER_0 : prevs are hexDir.opposite, hexDir.opposite.next 
          //case CORNER_1 : prevs are hexDir.opposite, hexDir.opposite.prev
          prevDirs.clear();
          prevDirs.add(opposite);
          prevDirs.add((intersection==Intersection.CORNER_0)?
                        opposite.next():opposite.prev());
        }
        //otherwise...
        else{
          //case CORNER_0 : prevs are hexDir.opposite, hexDir.opposite.prev 
          //case CORNER_1 : prevs are hexDir.opposite, hexDir.opposite.next
          prevDirs.clear();
          prevDirs.add(opposite);
          prevDirs.add((intersection==Intersection.CORNER_0)?
                        opposite.prev():opposite.next());
        }
        break;
    }
    return ret;
  }
  
  /*
   * Compute the direction of the hex that has the most clean intersections.
   */
  HexDirection _dirWithMoreIntersection(IntersectRayComputer irc,AbstractVisibilityHex currentHex,HexDirection dir1, HexDirection dir2){
    
    HexDirection ret=null;
    
    int nbHit1=_numberHitIntersectionWithHex(irc,new Hex.next(currentHex, dir1, 1));
    int nbHit2=_numberHitIntersectionWithHex(irc,new Hex.next(currentHex, dir2, 1));
    
    if(nbHit1>nbHit2){
      ret= dir1;
    }
    else if(nbHit2>nbHit1){
      ret= dir2;
    }
    return ret;
    
  }
  
  /*
   * Compute the number of hit intersections with an hex
   */
  int _numberHitIntersectionWithHex(IntersectRayComputer irc, Hex hex){
    int ret=0;
    if(hex!=null){
      HexDirection.values
          .forEach((hd){//find the edge that intersect our ray
            List<Point> edge=hd.getEdge(hex.relativeCenter,hex.pixelSize);
            Intersection i= irc.intersectAsRay(edge[0], edge[1]);
            if(i==Intersection.HIT){
              ret++;
            }
          });
    }
    
    return ret;
  }
  
  /*
   * Compute the ray visibility in case the ray is in a diagonal of the starting hex
   */
  void _visibleRayToDiag(HexDiagonal hexDiag, int distMax){
    
    log.fine("\nVisibleRayToDiag in diag : "+ hexDiag.toString()+"\t distMax : "+distMax.toString());    
    
    //initialize useful point for IntersectRayComputer
    Point fromCenter=from.relativeCenter;
    
    //Initial values
    AbstractVisibilityHex currentHex=from;
    int startAltitude=from.altitude;
    currentHex.visible=true;
    AbstractVisibilityHex nextHex=null;
    
    double hexSize=from.pixelSize;
    bool isDone=false;
       
    while(!isDone){     
      
      //evaluate the result.
      nextHex=currentHex.getVisibilityHexInDiag(hexDiag);
      
      //some logging...
      if(Logger.root.isLoggable(Level.FINER)){
        if(nextHex!=null){
        log.finer("Test nextHex: "+ nextHex.id);
          if(from.distanceTo(nextHex)>distMax){
            log.finer("next hex too far. Dist : "+from.distanceTo(nextHex).toString());
          }
        }
        else{
          log.fine("Test hex: is null");
        }
      }
      
      
      //if nextHex is null ot too far its over...
      if(nextHex==null || from.distanceTo(nextHex)>distMax){
        isDone=true;
      }
      //...otherwise we evaluate if the next hex is visible
      else{
        bool blockView=false;
        
        /*
         * the diag hex is considered visible if neither of the two hex before it in the direction the ray is coming
         * are blocking the view.
         */
        hexDiag.getPreviousDirections().forEach((dir){
          AbstractVisibilityHex prevHex=nextHex.getVisibilityHexInDir(dir);
          if(prevHex==null || !(startAltitude>=prevHex.altitude)){
            blockView=true;
          }
          
          log.finer("Previous direction : "+dir.toString()+ "\thex : "+(prevHex==null?"null":prevHex.id)+"\tblockView : "+blockView.toString());
          
        });
        
        if(!blockView){
          nextHex.visible=true;
          //prepare next step
          currentHex=nextHex;
        }
        //if blockView its over
        else{
          isDone=true;
        }
      }
    }
  }
  
}


/**
 * Interface defining object with which the AstarAlgorithm can work
 */
abstract class AbstractVisibilityHex implements Hex{  
  int get altitude;
  void set visible(bool v);
  
  /**
   * Give the VisibilityHex in the direction provided or null if there isn't one
   */
  AbstractVisibilityHex getVisibilityHexInDir(HexDirection dir);
  
  /**
   * Give the VisibilityHex in the diagonal provided or null if there isn't one
   */
  AbstractVisibilityHex getVisibilityHexInDiag(HexDiagonal dir); 
}