library astarAlgorithm;

import 'dart:collection';
import 'package:logging/logging.dart';

/**
 * A class implementing the Astar algorithm between two AStarObject elements.
 */
class AstarAlgorithm<T extends AStarObject>{
  
  final Logger log = new Logger('AstarAlgorithm');
  
  //the openList of element, thos possibly in the final path
  List<T> _openList;
  
  //list of elements already evaluated
  Set<T> _closeList;
  
  final T start;
  final T end;

  AstarAlgorithm(this.start, this.end){
    
    _openList= new List<T>();
    _closeList= new SplayTreeSet<T>((a,b){
      return (a.f-b.f);
    });
    
    //we initialize with the start point in the open list
    _addToOpenList(start);
  }
  
  Queue<T> execute(){
    
    log.info("\nexecute astar from : "+this.start.toString() +"\tto "+this.end.toString() );
    
    //take lowest F value element on from openList
    T lowF=_takeLowestF();
    
    while(lowF!=null && !lowF.equals(end)){
      
      log.fine("lowF element : "+lowF.toString());
      
      //put it in close list
      _addToCloseList(lowF);
      
      //find valid (walkable) objects from its adjacent elments
      lowF.getValidAdjacent().
        //for each adjacent elements that aren't in the close list... 
        where((a)=>(!a.closed)).
        forEach((a){
          //if a is not in the openList
          if(!a.open){
            a.parent=lowF;//set lowF as its parent
            _addToOpenList(a);
            log.finer("adjacent element added to open list : "+ a.toString());
          }
          //if it was already in the openList and lowF is a better parent
          else if(_isBetterGParent(a,lowF)){           
            a.parent=lowF;
            log.finer("adjacent takes lowF for parent : "+ a.toString());
          }   
        });
      
      //select new lowest F
      lowF=_takeLowestF();
    }
    
    log.info("algo stops with lowF : "+(lowF!=null?lowF.toString():"null"));
    
    //when algo stops
    Queue<T> ret= new Queue<T>();
    if(lowF!=null){
      ret.addLast(lowF);
      T parent=lowF.parent;
      while(parent!=null){
        ret.addFirst(parent);
        parent=parent.parent;
      }
    }
    return ret;
    
  }
  
  /**
   * Retrieve the object in the open list with the lowest F value, 
   * take it out of the list and return it
   * //TODO can be implemented more efficiently
   */
  T _takeLowestF(){
    T ret=null;
    if(_openList.length>0){
      _openList.sort((a,b){
        return (a.f-b.f);
      });
      ret= _openList.removeAt(0);
      ret.open=false; 
    }
    return ret;
  }
  
  void _addToOpenList(T o){
    o.open=true;
    _openList.add(o);
  }
  
  void _addAllToOpenList(Iterable<T> it){
    it.forEach((o)=>o.open=true);
    _openList.addAll(it);
  }
  
  void _addToCloseList(T o){
    o.closed=true;
    _closeList.add(o);
  }
  
  /*
   * Indicates if the parameter otherParent is a better parent for obj than its current parent;
   */
  bool _isBetterGParent(T obj, T otherParent){
    bool ret=false;
    if(obj.parent!=null){
      ret=obj.parent.g>otherParent.g;
    }
    
    return ret;
  }
  
}

/**
 * Interface defining object with which the AstarAlgorithm can work
 */
abstract class AStarObject{
  bool open;
  bool closed;
  int g;
  
  /**
   * retrieve an Iterable with all valid (meaning "walkable") adjacent element.
   */
  Iterable<AStarObject> getValidAdjacent();
  bool equals(AStarObject other);
  
  int get h;
  int get f;
  AStarObject get parent;
  void set parent(AStarObject parent);
  String toString();
}