
/**
 * Module to make some requests on lastFM.
 * Designed with definitive module pattern.
 */
var libLFM = (function () {

    /*
     * private elements
     */ 
    var _private = {
        apiKey: null,
        searchArtistUrl : 		'http://ws.audioscrobbler.com/2.0/?method=artist.search&format=json',
        artistExistUrl :  		'http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&format=json',
        getartisttracksUrl :	'http://ws.audioscrobbler.com/2.0/?method=user.getartisttracks&format=json',
        userInfoUrl : 		'http://ws.audioscrobbler.com/2.0/?method=user.getinfo&format=json',


        /*
         * Process LastFM json data of an user info to find if it exists.
         */
        isDataUserValid: function(data){
        	return (typeof data.error == 'undefined');
        },
        
        /*
         * Process LastFM json data of an artist search to indicate if the data is valid
         */
        isSearchArtistValid: function(data){
        	return !(typeof data.results.artistmatches == 'string');
        },
        
        /*
         * Process LastFM json data of an artist to find if it exists.
         */
        isDataArtistValid: function(data){
        	return (typeof data.error == 'undefined');
        },
        
        /*
         * Process LastFM json data of trackList to find if there are some.
         */
        hasTracks: function(data){
        	return (!(typeof data.artisttracks == 'undefined')
        			&& data.artisttracks.track.length>0);
        },
    };

    /*
     * public methods 
     */
    var _public = {
    	
    	//set the LastFM api key
    	setApiKey: function(pApiKey) {
    		_private.apiKey = pApiKey;
    	},

    	/**
    	 * Looks for a specific username according to pUserName and compute if it is valid.
    	 * The indication of the user validity is processed by the pHandler(boolean) parameter.
    	 * returns an ajax request asking for lastFM data of an user.
    	 */
    	userExists:function(pUserName, pHandler){
    		
    		return $.ajax({

    			url : _private.userInfoUrl, // api url
    			dataType : 'json', // json type
    			data : {
    				user : pUserName,
    				api_key : _private.apiKey,
    			},
    		
    			success : function(data){
    				//compute if received data user is valid
    				var isUserValid = _private.isDataUserValid(data);
    				
    				//call handler with appropriate value
    				pHandler(isUserValid);
    			}
    		});
    	},
    	
    	/**
    	 * Looks for a specific artist according to pArtistName and compute if the artist is valid.
    	 * The indication of the artist validity is processed by the pHandler(boolean) parameter.
    	 * returns an ajax request asking for lastFM data of an artist.
    	 */
    	artistExists:function(pArtistName, pHandler){
    		return $.ajax({
    			url : _private.artistExistUrl, //api url
    			dataType : 'json', // json data type					
    			data : {
    				artist : pArtistName,
    				api_key : _private.apiKey
    			},
    			success : function(data){
    				//compute if the artist exist
    				isValid = _private.isDataArtistValid(data);
    				
    				//call the handler to process the information
    				pHandler(isValid);
    			},
    		});
    	},
    	
    	/**
    	 * Looks for the a list of artist related to pArtistName, limited to  pLimit elements.
    	 * The data is processed by the pHandler(data) parameter.
    	 * returns an ajax request asking for lastFM data as json file
    	 */
    	searchArtist:function(pArtistName, pLimit, pHandler){
    		return $.ajax({
    			url : _private.searchArtistUrl, //api url
    			dataType : 'json', //data is json					
    			data : {
    				artist : pArtistName,
    				api_key : _private.apiKey,
    				limit : pLimit
    			},
    			success : pHandler,
    		})
    	},
    	
    	/**
    	 * Looks for the a list of artist related to pArtistName, limited to  pLimit elements.
    	 * The data is processed by the pHandler(array) parameter.
    	 * returns an ajax request asking for lastFM data as json file
    	 */
    	searchArtistAsArray:function(pArtistName, pLimit, pHandler){
    		return $.ajax({
    			url : _private.searchArtistUrl, //api url
    			dataType : 'json', //data is json					
    			data : {
    				artist : pArtistName,
    				api_key : _private.apiKey,
    				limit : pLimit
    			},
    			success :function(data){
    				var artistsArray =[];
    				
    				
    				if ( _private.isSearchArtistValid(data)){
    					var artistData=data.results.artistmatches.artist;
						
    					//if array of results, filter irrelevant ones.
						if($.isArray(artistData)){
							artistData.filter(function(object){
								return (typeof object.listeners != 'undefined');
							});
							artistsArray = artistData;
						}
						//else  it means there is only one result, convert it as an array.
						else{
							artistsArray = [artistData];
						}
						
						//converts each data into a simpler object.
						artistsArray = $.map(artistsArray, function(object){
							var obj={ 
								name: object.name,
								image: object.image[0]["#text"],
								value: object.name
							};
							return obj;
						});
					}
    				
    				//process array
    				pHandler(artistsArray);
    			}, 
    		})
    	},
    	
    	/**
    	 * Looks for the list tracks of artist pArtistName,listened by user pUserName.
    	 * The data is processed by the pHasTrackHandler(data) parameter if there are tracks and pNoTrackHandler() if not.
    	 * returns an ajax request asking for lastFM listened tracks as json file
    	 */
    	getArtistTracks:function(pUserName,pArtistName, pHasTrackHandler, pNoTrackHandler){
    		return $.ajax({
    			url : _private.getartisttracksUrl, //api url 
    			dataType : 'json', //json data type 					
    			data : {
    				artist : pArtistName, //artist
    				user : pUserName, //user
    				api_key : _private.apiKey
    			},
    			success : function(data){
    				//call handler aaccording to track existence.
    				if(_private.hasTracks(data)){
    					pHasTrackHandler(data.artisttracks.track);
    				}
    				else{
    					pNoTrackHandler();
    				}
    			},	
    		});
    	},
    };

    return _public;

})();