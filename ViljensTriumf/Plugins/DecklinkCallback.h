//
//  DecklinkCallback.h
//  ViljensTriumf
//
//  Created by Jonas on 10/3/12.
//
//
#include <vector>

#include "DeckLinkAPI.h"
class DecklinkCallback : public IDeckLinkInputCallback{
public:
    DecklinkCallback();
    
    unsigned char * bytes;
    int w;
    int h;
    int size;
    bool newFrame;
    
    unsigned char                                red[256][256];
    unsigned char                                blue[256][256];
    unsigned char                                green[256][256][256];
    
    // IUnknown needs only a dummy implementation
	virtual HRESULT		QueryInterface (REFIID iid, LPVOID *ppv)	{return E_NOINTERFACE;}
	virtual ULONG		AddRef ()									{return 1;}
	virtual ULONG		Release ()									{return 1;}
    
    
    
    virtual HRESULT		VideoInputFormatChanged (/* in */ BMDVideoInputFormatChangedEvents notificationEvents, /* in */ IDeckLinkDisplayMode *newDisplayMode, /* in */ BMDDetectedVideoInputFormatFlags detectedSignalFlags);
	virtual HRESULT		VideoInputFrameArrived (/* in */ IDeckLinkVideoInputFrame* videoFrame, /* in */ IDeckLinkAudioInputPacket* audioPacket);
    
    
    unsigned char Clamp(int value);
    void CreateLookupTables();
    void YuvToARgbChunk(unsigned char *yuv, unsigned char * argb, unsigned int offset, unsigned int chunk_size);
    unsigned char * YuvToARgb(IDeckLinkVideoInputFrame* pArrivedFrame);
    
    pthread_mutex_t mutex;

    unsigned char * argb;
    
    IDeckLinkOutput * output;
    IDeckLinkVideoConversion * converter;
};

