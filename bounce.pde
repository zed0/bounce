#include "lib/PCD8544/PCD8544.h"

// pin 13 - Serial clock out (SCLK)
// pin 11 - Serial data out (DIN)
// pin 08 - Data/Command select (D/C)
// pin 10 - LCD chip select (CS)
// pin 09 - LCD reset (RST)
PCD8544 nokia = PCD8544(13,11,8,10,9);
const int backLightPin = 7;
const int fps = 20;
int sizeX = LCDWIDTH;
int sizeY = LCDHEIGHT;

const int numBalls = 2;
struct ball
{
	float posX;
	float posY;
	float velocityX;
	float velocityY;
	int radius;
	int colour;
	void move();
	void draw();
	void init();
	bool getCollision(ball);
	void bounce(ball);
} balls[numBalls];

void ball::move()
{
	posX += velocityX;
	posY += velocityY;
	if(posX <= 0)
	{
		posX = -posX;
		velocityX = -velocityX;
	}
	if(posX >= sizeX)
	{
		posX = 2*sizeX - posX;
		velocityX = -velocityX;
	}
	if(posY <= 0)
	{
		posY = -posY;
		velocityY = -velocityY;
	}
	if(posY >= sizeY)
	{
		posY = 2*sizeY - posY;
		velocityY = -velocityY;
	}
}

void ball::draw()
{
	if(colour == BLACK)
	{
		nokia.fillcircle(int(posX), int(posY), radius, BLACK);
	}
	else
	{
		nokia.drawcircle(int(posX), int(posY), radius, BLACK);
	}
}

void ball::init()
{

	posX = random(840)/10.0;
	posY = random(480)/10.0;
	velocityX = random(-10,10)/5.0;
	velocityY = random(-10,10)/5.0;
	radius = random(5);
	colour = BLACK;
}

void ball::bounce(ball target)
{
	//colour = !colour;
	//target.colour = !target.colour;
	/*
	float mass1 = radius*radius*radius;
	float mass2 = target.radius*target.radius*target.radius;
	float totMass = mass1+mass2;
	if(totMass!=0.0)
	{
		float velocityX1 = ((mass1-mass2)*velocityX + (2*mass2)*target.velocityX)/totMass;
		float velocityY1 = ((mass1-mass2)*velocityY + (2*mass2)*target.velocityY)/totMass;
		float velocityX2 = ((mass1-mass2)*target.velocityX + (2*mass1)*velocityX)/totMass;
		float velocityY2 = ((mass1-mass2)*target.velocityY + (2*mass1)*velocityY)/totMass;
		velocityX = velocityX1;
		velocityY = velocityY1;
		target.velocityX = velocityX2;
		target.velocityY = velocityY2;
	}
	*/
	float deltaX = posX - target.posX;
	float deltaY = posY - target.posY;
	float totRadius = radius + target.radius;
	float d = sqrt(deltaX*deltaX+deltaY*deltaY);
	float mtdX = deltaX*(totRadius-d)/d;
	float mtdY = deltaY*(totRadius-d)/d;
	float im1 = 0.5;//1/(radius);
	float im2 = 0.5;//1/(target.radius);
	posX = posX+(mtdX*(im1/(im1+im2)));
	posY = posY+(mtdY*(im1/(im1+im2)));
	target.posX = target.posX+(mtdX*(im2/(im1+im2)));
	target.posY = target.posY+(mtdY*(im2/(im1+im2)));

	float vX = velocityX - target.velocityX;
	float vY = velocityY - target.velocityY;

	float mtdMag = sqrt(mtdX*mtdX+mtdY*mtdY);
	float vn = (vX*mtdX + vY*mtdY)/mtdMag;

	if(vn > 0.0f)
	{
		return;
	}

	float restitution = 1;
	float i = (-(1.0f + restitution) * vn)/(im1+im2);
	float impulseX = mtdX*i;
	float impulseY = mtdY*i;

	velocityX = velocityX + impulseX*im1;
	velocityY = velocityY + impulseY*im1;
	target.velocityX = target.velocityX + impulseX*im2;
	target.velocityY = target.velocityY + impulseY*im2;
}

bool ball::getCollision(ball target)
{
	float distanceX = posX - target.posX;
	float distanceY = posY - target.posY;
	float totRadius = radius + target.radius;
	if(distanceX*distanceX + distanceY*distanceY < totRadius*totRadius)
	{
		return true;
	}
	else
	{
		return false;
	}
}

void setup(void)
{
	pinMode(backLightPin, OUTPUT);
	randomSeed(analogRead(1));
	for(int i=0; i<numBalls; ++i)
	{
		balls[i].init();
		balls[i].colour = i;
	}
	digitalWrite(backLightPin, HIGH);
	nokia.init();
	nokia.setContrast(40);
	nokia.clear();
	nokia.setCursor(0,0);
}

void loop(void)
{
	nokia.clear();
	int joystick = analogRead(A0);
	nokia.println(joystick);
	for(int i=0; i<numBalls; ++i)
	{
		for(int j=i+1; j<numBalls; ++j)
		{
			if(balls[i].getCollision(balls[j]))
			{
				balls[i].bounce(balls[j]);
			}
		}
		balls[i].move();
		balls[i].draw();
	}
	nokia.display();
	frame_wait();
}

void frame_wait()
{
	static unsigned long lastTime = 0;
	while(millis() - lastTime <= 1000/fps)
	{
		delay(1);
	}
	lastTime = millis();
}
