
/* 
 * File:   TerminalUI.cpp
 * Author: Richard Greene
 * 
 * Implements the terminal as a UI component, for getting status updates.
 * (Terminal input is also accepted, via stdin in EventHandler.)
 *
 * Created on April 18, 2014, 4:54 PM
 */

#include <iostream>

#include <TerminalUI.h>
#include <PrinterStatus.h>
#include <MessageStrings.h>

#include "Logger.h"

void TerminalUI::Callback(EventType eventType, void* data)
{     
    PrinterStatus* pPS;
    char statusMsg[256];
    const char* change = "";
    const char* substate = "";
    switch(eventType)
    {               
        case PrinterStatusUpdate:
            pPS = (PrinterStatus*)data;
            if(pPS->_change == Entering)
                change = "entering ";
            else if(pPS->_change == Leaving)
                change = "leaving ";
            
            if(pPS->_UISubState != NoUISubState)
                substate = SUBSTATE_NAME(pPS->_UISubState);
            
            std::cout <<  change << STATE_NAME(pPS->_state) << " " << substate;

            if(pPS->_currentLayer != 0) // if we're printing, show additional status 
            {
                sprintf(statusMsg, PRINTER_STATUS_FORMAT, pPS->_currentLayer, 
                        pPS->_numLayers,
                        pPS->_estimatedSecondsRemaining);
                std::cout << statusMsg;             
            }
            std::cout << std::endl;
            break;

        default:
            LOGGER.LogError(LOG_WARNING, errno, ERR_MSG(UnexpectedEvent), eventType);
            break;
    }
}
