import Toybox.Lang;
using Toybox.FitContributor as Fit;

// see https://github.com/garmin/connectiq-apps for reference on FitContributor

const TEMPERATURE_FIELD_RECORD_ID = 0;
const TEMPERATURE_NATIVE_NUM_RECORD_MESG = 3;


const TEMPERATURE_FIELD_SESSION_MIN_ID = 80;
const TEMPERATURE_FIELD_SESSION_MAX_ID = 81;
const TEMPERATURE_FIELD_SESSION_AVG_ID = 82;
const TEMPERATURE_FIELD_LAP_MIN_ID = 83;
const TEMPERATURE_FIELD_LAP_MAX_ID = 84;
const TEMPERATURE_FIELD_LAP_AVG_ID = 85;

/*
const TEMPERATURE_NATIVE_NUM_SESSION_MIN_MESG = 86;
const TEMPERATURE_NATIVE_NUM_SESSION_MAX_MESG = 87;
const TEMPERATURE_NATIVE_NUM_SESSION_AVG_MESG = 88;

const TEMPERATURE_NATIVE_NUM_LAP_MIN_MESG = 63;
const TEMPERATURE_NATIVE_NUM_LAP_MAX_MESG = 16;
const TEMPERATURE_NATIVE_NUM_LAP_AVG_MESG = 15;
*/
const TEMPERATURE_UNITS = "°C";

class Thermo357Fit {

    protected var mTemperatureRecordField;
    protected var mMinTemperatureSessionField;
    protected var mMaxTemperatureSessionField;
    protected var mAvgTemperatureSessionField;
    protected var mMinTemperatureLapField;
    protected var mMaxTemperatureLapField;
    protected var mAvgTemperatureLapField;
    
	protected var mTimerRunning = false;
	protected var mSessionStats;
	protected var mLapStats;

    function initialize(dataField) {

       
        mTemperatureRecordField = dataField.createField("temperature", 
          TEMPERATURE_FIELD_RECORD_ID, Fit.DATA_TYPE_FLOAT, 
          { :nativeNum=>TEMPERATURE_NATIVE_NUM_RECORD_MESG, :mesgType=>Fit.MESG_TYPE_RECORD, :units=>TEMPERATURE_UNITS });
        debug_prt("Thermo357Fit field: " + mTemperatureRecordField, null);

        
        /* session */
        mSessionStats = new MinMaxAvg(false);
        mMinTemperatureSessionField = dataField.createField("min_temperature", TEMPERATURE_FIELD_SESSION_MIN_ID, Fit.DATA_TYPE_FLOAT, { /*:nativeNum=>TEMPERATURE_NATIVE_NUM_SESSION_MIN_MESG,*/ :mesgType=>Fit.MESG_TYPE_SESSION, :units=>TEMPERATURE_UNITS });
        mMaxTemperatureSessionField = dataField.createField("max_temperature", TEMPERATURE_FIELD_SESSION_MAX_ID, Fit.DATA_TYPE_FLOAT, { /*:nativeNum=>TEMPERATURE_NATIVE_NUM_SESSION_MAX_MESG,*/ :mesgType=>Fit.MESG_TYPE_SESSION, :units=>TEMPERATURE_UNITS });
        mAvgTemperatureSessionField = dataField.createField("avg_temperature", TEMPERATURE_FIELD_SESSION_AVG_ID, Fit.DATA_TYPE_FLOAT, { /*:nativeNum=>TEMPERATURE_NATIVE_NUM_SESSION_AVG_MESG,*/ :mesgType=>Fit.MESG_TYPE_SESSION, :units=>TEMPERATURE_UNITS });
        
        /* lap */
        mLapStats = new MinMaxAvg(false);
        mMinTemperatureLapField = dataField.createField("min_temperature", TEMPERATURE_FIELD_LAP_MIN_ID, Fit.DATA_TYPE_FLOAT, { /*:nativeNum=>TEMPERATURE_NATIVE_NUM_LAP_MIN_MESG,*/ :mesgType=>Fit.MESG_TYPE_LAP, :units=>TEMPERATURE_UNITS });
        mMaxTemperatureLapField = dataField.createField("max_temperature", TEMPERATURE_FIELD_LAP_MAX_ID, Fit.DATA_TYPE_FLOAT, { /*:nativeNum=>TEMPERATURE_NATIVE_NUM_LAP_MAX_MESG,*/ :mesgType=>Fit.MESG_TYPE_LAP, :units=>TEMPERATURE_UNITS });
        mAvgTemperatureLapField = dataField.createField("avg_temperature", TEMPERATURE_FIELD_LAP_AVG_ID, Fit.DATA_TYPE_FLOAT, { /*:nativeNum=>TEMPERATURE_NATIVE_NUM_LAP_AVG_MESG,*/ :mesgType=>Fit.MESG_TYPE_LAP, :units=>TEMPERATURE_UNITS });

        
    }


    function setTemperatureData(temp10) {
        //debug_prt("Thermo357Fit.setTemperatureData: " + temp10/10.0 + " °C", null);
        var ftemp = temp10/10.0;
    	mTemperatureRecordField.setData(ftemp);
    	
        
    	if(mTimerRunning) {
    		mSessionStats.setData(ftemp);
    		mLapStats.setData(ftemp);
    		
			mMinTemperatureSessionField.setData(mSessionStats.min());
			mMaxTemperatureSessionField.setData(mSessionStats.max());
			mAvgTemperatureSessionField.setData(mSessionStats.avg());
			
			mMinTemperatureLapField.setData(mLapStats.min());
			mMaxTemperatureLapField.setData(mLapStats.max());
			mAvgTemperatureLapField.setData(mLapStats.avg());
    	}
    }
    function onStart() {
        debug_prt("fit onStart", null);
    	mTimerRunning = false;
    	mSessionStats = new MinMaxAvg(false);
    	mLapStats = new MinMaxAvg(false);
    }
    function onStop()  {
        debug_prt("fit onStop", null);
    }
    function onNextMultisportLeg() {
        // ???
        debug_prt("fit onNextMultisportLeg", null);
    	mSessionStats.reset();
    	mLapStats.reset();
    }

    function onTimerLap() {
        debug_prt("fit onTimerLap", null);
    	mLapStats.reset();
    }
    
    function onTimerReset() {
        debug_prt("fit onTimerReset", null);
    	mSessionStats.reset();
    	mLapStats.reset();
    }
    
    function onTimerPause() {
        debug_prt("fit onTimerPause", null);
    	mTimerRunning = false;
    }
    
    function onTimerResume() {
        debug_prt("fit onTimerResume", null);
        mTimerRunning = true;
    }
    
    function onTimerStart() {
        debug_prt("fit onTimerStart", null);
        mTimerRunning = true;
    }

    function onTimerStop() {
        debug_prt("fit onTimerStop", null);
        mTimerRunning = false;
    }

}