#include "tinaplayer.h"
#include <string.h>
#include <tina_log.h>
#include "awplayer.h"

#define TAG "TinaPlayer"
#define CONFIG_LOG_LEVEL OPTION_LOG_LEVEL_DETAIL

#define SAVE_PCM_DATA 1

#if SAVE_PCM_DATA
	FILE* savaPcmFd = NULL;
#endif

namespace aw{

	typedef struct TinaPlayerContext
	{
		AwPlayer*		mAwPlayer;
		pthread_mutex_t mMutex;
	}TinaPlayerContext;

	TinaPlayerContext 	gTinaPlayerContext;
	NotifyCallback		gNotifier;
	void*				gUserData;
	SoundCtrl* gSoundCtrl = NULL;

	static SoundCtrl* _SoundDeviceInit(void* pAudioSink){
		TLOGD(" _SoundDeviceInit\n");
		gSoundCtrl = TinaSoundDeviceInit(pAudioSink);
		if(gSoundCtrl == NULL){
			TLOGD(" _SoundDeviceInit,ERR:gSoundCtrl == NULL\n");
		}
		return gSoundCtrl;
	}

	static void _SoundDeviceRelease(SoundCtrl* s){
		TLOGD(" _SoundDeviceRelease\n");
		TinaSoundDeviceRelease(s);
	}

	static void _SoundDeviceSetFormat(SoundCtrl* s, unsigned int nSampleRate, unsigned int nChannelNum){
		TLOGD(" _SoundDeviceSetFormat\n");
		TinaSoundDeviceSetFormat(s, nSampleRate, nChannelNum);
	}

	static int _SoundDeviceStart(SoundCtrl* s){
		TLOGD(" _SoundDeviceStart\n");
		return TinaSoundDeviceStart(s);
	}

	static int _SoundDeviceStop(SoundCtrl* s){
		TLOGD(" _SoundDeviceStop\n");
		return TinaSoundDeviceStop(s);
	}

	static int _SoundDevicePause(SoundCtrl* s){
		TLOGD(" _SoundDevicePause\n");
		return TinaSoundDevicePause(s);
	}

	static int _SoundDeviceWrite(SoundCtrl* s, void* pData, int nDataSize){
		//TLOGD(" _SoundDeviceWrite\n");
		int ret = TinaSoundDeviceWrite(s, pData, nDataSize);
		#if SAVE_PCM_DATA
			if(savaPcmFd!=NULL){
				int write_ret = fwrite(pData, 1, nDataSize, savaPcmFd);
				//TLOGD("PCM write_ret = %d\n",write_ret);
				if(write_ret <= 0){
					TLOGD("err str: %s\n",strerror(errno));
				}
			}
		#endif
		return ret;
	}

	static int _SoundDeviceReset(SoundCtrl* s){
		TLOGD(" _SoundDeviceReset\n");
		return TinaSoundDeviceReset(s);
	}

	static int _SoundDeviceGetCachedTime(SoundCtrl* s){
		//TLOGD(" _SoundDeviceGetCachedTime\n");
		return TinaSoundDeviceGetCachedTime(s);
	}

	
	static SoundCtrl* _SoundDeviceInit_raw(void* raw_data,void* hdeccomp,RawCallback callback){
		return TinaSoundDeviceInit_raw(raw_data,hdeccomp,callback);
	}
	
	static void _SoundDeviceRelease_raw(SoundCtrl* s){
		TinaSoundDeviceRelease_raw(s);
	}

	static void _SoundDeviceSetFormat_raw(SoundCtrl* s, unsigned int nSampleRate, unsigned int nChannelNum){
		TinaSoundDeviceSetFormat_raw(s, nSampleRate, nChannelNum);
	}

	static int _SoundDeviceStart_raw(SoundCtrl* s){
		return TinaSoundDeviceStart_raw(s);
	}

	static int _SoundDeviceStop_raw(SoundCtrl* s){
		return TinaSoundDeviceStop_raw(s);
	}

	static int _SoundDevicePause_raw(SoundCtrl* s){
		return TinaSoundDevicePause_raw(s);
	}

	static int _SoundDeviceWrite_raw(SoundCtrl* s, void* pData, int nDataSize){
		return TinaSoundDeviceWrite_raw(s, pData, nDataSize);
	}

	static int _SoundDeviceReset_raw(SoundCtrl* s){
		return TinaSoundDeviceReset_raw(s);
	}

	static int _SoundDeviceGetCachedTime_raw(SoundCtrl* s){
		return TinaSoundDeviceGetCachedTime_raw(s);
	}

	static int _SoundDeviceSetVolume(SoundCtrl* s, float volume){
		TLOGD(" _SoundDeviceSetVolume\n");
		return TinaSoundDeviceSetVolume(s, volume);
	}

	static int _SoundDeviceGetVolume(SoundCtrl* s, float *volume){
		TLOGD(" _SoundDeviceGetVolume\n");
		return TinaSoundDeviceGetVolume(s, volume);
	}

	static int _SoundDeviceSetCallback (SoundCtrl* s, SndCallback callback, void* pUserData){
		TLOGD(" _SoundDeviceSetCallback\n");
		return TinaSoundDeviceSetCallback(s, callback, pUserData);
	}

	static SoundControlOpsT gSoundControl;
	
	//* a callback for awplayer.
	void CallbackForAwPlayer(void* pUserData, int msg, int param0, void* param1)
	{
	    TinaPlayerContext* tinaPlayerContext = (TinaPlayerContext*)pUserData;

	    switch(msg)
	    {
	        case NOTIFY_NOT_SEEKABLE:
	        {
				TLOGD(" NOTIFY_NOT_SEEKABLE\n");
				if(gNotifier != NULL)
				{
					gNotifier(gUserData, TINA_NOTIFY_NOT_SEEKABLE, param0, param1);
				}
	            break;
	        }
	        
	        case NOTIFY_ERROR:
	        {
				TLOGD(" NOTIFY_ERROR\n");
				if(gNotifier != NULL)
				{
					gNotifier(gUserData, TINA_NOTIFY_ERROR, param0, param1);
				}
	            break;
	        }
	            
	        case NOTIFY_PREPARED:
	        {
				TLOGD(" NOTIFY_PREPARED\n");
				if(gNotifier != NULL)
				{
					gNotifier(gUserData, TINA_NOTIFY_PREPARED, param0, param1);
				}
	            break;
	        }
	            
	        case NOTIFY_BUFFERRING_UPDATE:
	        {
	            //int nBufferedFilePos;
	            //int nBufferFullness;
	            
	            //nBufferedFilePos = param0 & 0x0000ffff;
	            //nBufferFullness  = (param0>>16) & 0x0000ffff;
	            //TLOGD("info: buffer %d percent of the media file, buffer fullness = %d percent.\n", 
	            //    nBufferedFilePos, nBufferFullness);
	            TLOGD(" NOTIFY_BUFFERRING_UPDATE\n");
	            if(gNotifier != NULL)
				{
					gNotifier(gUserData, TINA_NOTIFY_BUFFERRING_UPDATE, param0, param1);
				}
	            break;
	        }
	            
	        case NOTIFY_PLAYBACK_COMPLETE:
	        {
	            TLOGD(" NOTIFY_PLAYBACK_COMPLETE\n");
				printf(" ****NOTIFY_PLAYBACK_COMPLETE****\n");
				_SoundDeviceStop(gSoundCtrl);
				if(gNotifier != NULL)
				{
					gNotifier(gUserData, TINA_NOTIFY_PLAYBACK_COMPLETE, param0, param1);
				}
	            break;
	        }
	            
	        case NOTIFY_RENDERING_START:
	        {
	            TLOGD(" NOTIFY_RENDERING_START\n");
				if(gNotifier != NULL)
				{
					gNotifier(gUserData, TINA_NOTIFY_RENDERING_START, param0, param1);
				}
	            break;
	        }
	        
	        case NOTIFY_SEEK_COMPLETE:
	        {
	            TLOGD(" NOTIFY_SEEK_COMPLETE\n");
				if(gNotifier != NULL)
				{
					gNotifier(gUserData, TINA_NOTIFY_SEEK_COMPLETE, param0, param1);
				}
	            break;
	        }

	        case NOTIFY_VIDEO_FRAME:
	        {
				//in this version,NOTIFY_VIDEO_FRAME can not be called backed,20160320
				
				//VideoPicData* videodata = (VideoPicData*)param1;
				//if(videodata)
				//{
				//	if(videodata->ePixelFormat == VIDEO_PIXEL_FORMAT_YUV_MB32_420)
				//	{
				//		char filename[024];
			    //    	sprintf(filename, "/mnt/UDISK/mb32_%d.dat", pDemoPlayer->mVideoFrameNum);
			    //    	FILE* outFp = fopen(filename, "wb");
			    //    	if(outFp != NULL)
				//	    {
				//	    	int height64Align = (videodata->nHeight + 63)& ~63;
				//	    	fwrite(videodata->pData0, videodata->nWidth*videodata->nHeight, 1, outFp);
				//	    	fwrite(videodata->pData1, videodata->nWidth*height64Align/2, 1, outFp);
				//	    	fclose(outFp);
				//	    }
				//	}
			    //}	
				TLOGD(" NOTIFY_VIDEO_FRAME\n");
	        	break;
	        }

	        case NOTIFY_AUDIO_FRAME:
	        {
				//in this version,NOTIFY_AUDIO_FRAME can not be called backed,20160320
				
				//TLOGD(" NOTIFY_AUDIO_FRAME\n");
				//AudioPcmData* pcmData = (AudioPcmData*)param1;
				//#if SAVE_PCM_DATA
				//	if(savaPcmFd!=NULL){
				//		int write_ret = fwrite(pcmData->pData, 1, pcmData->nSize, savaPcmFd);
						//TLOGD("PCM write_ret = %d\n",write_ret);
				//		if(write_ret <= 0){
				//			TLOGD("err str: %s\n",strerror(errno));
				//		}
				//	}
				//#endif
	        	break;
	        }

	        case NOTIFY_VIDEO_PACKET:
	        {
	        	//DemuxData* videoData = (DemuxData*)param1;
				//logd("videoData pts: %lld", videoData->nPts);
				//static int frame = 0;
				//if(frame == 0)
				//{
				//	FILE* outFp = fopen("/mnt/UDISK/video.jpg", "wb");
		        //	if(videoData->nSize0)
		        //	{
		        //		fwrite(videoData->pData0, 1, videoData->nSize0, outFp);
		        //	}
		        //	if(videoData->nSize1)
		        //	{
		        //		fwrite(videoData->pData1, 1, videoData->nSize1, outFp);
		        //	}
		        //	fclose(outFp);
		        //	frame ++;
	        	//}
	        	//TLOGD(" NOTIFY_VIDEO_PACKET\n");
	        	break;
	        }

	        case NOTIFY_AUDIO_PACKET:
	        {
	        	//DemuxData* audioData = (DemuxData*)param1;
				//logd("audio pts: %lld", audioData->nPts);
				//static int audioframe = 0;
				//if(audioframe == 0)
				//{
				//	FILE* outFp = fopen("/mnt/UDISK/audio.pcm", "wb");
		        //	if(audioData->nSize0)
		        //	{
		        //		fwrite(audioData->pData0, 1, audioData->nSize0, outFp);
		        //	}
		        //	if(audioData->nSize1)
		        //	{
		        //		fwrite(audioData->pData1, 1, audioData->nSize1, outFp);
		        //	}
		        //	fclose(outFp);
		        //	audioframe ++;
	        	//}
	        	//TLOGD(" NOTIFY_AUDIO_PACKET\n");
	        	break;
	        	
	        }
	        
	        default:
	        {
	            //TLOGD("warning: unknown callback from AwPlayer.\n");
	            //TLOGD(" warning: unknown callback from AwPlayer\n");
	            break;
	        }
	    }
	    
	    return;
	}
	TinaPlayer::TinaPlayer()
	{
		TLOGD(" TinaPlayer()\n");
		gNotifier = NULL;
		gUserData = NULL;
		memset(&gTinaPlayerContext, 0, sizeof(TinaPlayerContext));
		pthread_mutex_init(&gTinaPlayerContext.mMutex, NULL);
		gTinaPlayerContext.mAwPlayer = new AwPlayer();
		initSoundControlOpsT();
		gTinaPlayerContext.mAwPlayer->setControlOps(NULL, &gSoundControl);
	}
	
	TinaPlayer::~TinaPlayer()
	{
		TLOGD(" ~TinaPlayer()\n");
		if(gTinaPlayerContext.mAwPlayer != NULL){
			delete gTinaPlayerContext.mAwPlayer;
    		gTinaPlayerContext.mAwPlayer = NULL;
		}
		pthread_mutex_destroy(&gTinaPlayerContext.mMutex);
	}

	void TinaPlayer::initSoundControlOpsT(){
		gSoundControl.SoundDeviceInit = _SoundDeviceInit;
		gSoundControl.SoundDeviceRelease = _SoundDeviceRelease;
		gSoundControl.SoundDeviceSetFormat = _SoundDeviceSetFormat;
		gSoundControl.SoundDeviceStart = _SoundDeviceStart;
		gSoundControl.SoundDeviceStop = _SoundDeviceStop;
		gSoundControl.SoundDevicePause = _SoundDevicePause;
		gSoundControl.SoundDeviceWrite = _SoundDeviceWrite;
		gSoundControl.SoundDeviceReset = _SoundDeviceReset;
		gSoundControl.SoundDeviceGetCachedTime = _SoundDeviceGetCachedTime;
		gSoundControl.SoundDeviceInit_raw = _SoundDeviceInit_raw;
		gSoundControl.SoundDeviceRelease_raw = _SoundDeviceRelease_raw;
		gSoundControl.SoundDeviceSetFormat_raw = _SoundDeviceSetFormat_raw;
		gSoundControl.SoundDeviceStart_raw = _SoundDeviceStart_raw;
		gSoundControl.SoundDeviceStop_raw = _SoundDeviceStop_raw;
		gSoundControl.SoundDevicePause_raw = _SoundDevicePause_raw;
		gSoundControl.SoundDeviceWrite_raw = _SoundDeviceWrite_raw;
		gSoundControl.SoundDeviceReset_raw = _SoundDeviceReset_raw;
		gSoundControl.SoundDeviceGetCachedTime_raw = _SoundDeviceGetCachedTime_raw;
		gSoundControl.SoundDeviceSetVolume = _SoundDeviceSetVolume;
		gSoundControl.SoundDeviceGetVolume = _SoundDeviceGetVolume;
		gSoundControl.SoundDeviceSetCallback = _SoundDeviceSetCallback;
	}
	
	int TinaPlayer::initCheck()
	{
		return gTinaPlayerContext.mAwPlayer->initCheck();
	}
	
	int TinaPlayer::setNotifyCallback(NotifyCallback notifier, void* pUserData)
	{
		gNotifier = notifier;
		gUserData = pUserData;
		return gTinaPlayerContext.mAwPlayer->setNotifyCallback(CallbackForAwPlayer, (void*)&gTinaPlayerContext);
	}
	
	int TinaPlayer::setDataSource(const char* pUrl, const map<string, string>* pHeaders)
	{
		return gTinaPlayerContext.mAwPlayer->setDataSource(pUrl, pHeaders);
	}
	
	
	int TinaPlayer::prepareAsync()
	{
		return gTinaPlayerContext.mAwPlayer->prepareAsync();
	}
	
	int TinaPlayer::prepare()
	{
		return gTinaPlayerContext.mAwPlayer->prepare();
	}
	
	int TinaPlayer::start()
	{
		#if SAVE_PCM_DATA
			savaPcmFd = fopen("/mnt/UDISK/save.pcm", "wb");
			if(savaPcmFd==NULL){
				TLOGD("fopen save.pcm fail****\n");
				TLOGD("err str: %s\n",strerror(errno));
			}else{
				fseek(savaPcmFd,0,SEEK_SET);
			}
		#endif
		
		return gTinaPlayerContext.mAwPlayer->start();
	}
	
	int TinaPlayer::stop()
	{
		#if SAVE_PCM_DATA
			if(savaPcmFd!=NULL){
				fclose(savaPcmFd);
			}
		#endif
		return gTinaPlayerContext.mAwPlayer->stop();
	}
	
	int TinaPlayer::pause()
	{
		return gTinaPlayerContext.mAwPlayer->pause();
	}
	
	int TinaPlayer::seekTo(int msec)
	{
		return gTinaPlayerContext.mAwPlayer->seekTo(msec);
	}
	
	int TinaPlayer::reset()
	{
		return gTinaPlayerContext.mAwPlayer->reset();
	}
	
	
	int TinaPlayer::isPlaying()
	{
		return gTinaPlayerContext.mAwPlayer->isPlaying();
	}
	
	
	int TinaPlayer::getCurrentPosition(int* msec)
	{
		return gTinaPlayerContext.mAwPlayer->getCurrentPosition(msec);
	}
	
	
	int TinaPlayer::getDuration(int *msec)
	{
		return gTinaPlayerContext.mAwPlayer->getDuration(msec);
	}
	
	
	int TinaPlayer::setLooping(int loop)
	{
		return gTinaPlayerContext.mAwPlayer->setLooping(loop);
	}

	/*now,this function do not do */
	int TinaPlayer::setVolume(int volume)
	{
		return gTinaPlayerContext.mAwPlayer->setVolume(volume);
	}

}
