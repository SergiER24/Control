y3 = out.salida2;   % ±1 °C

figure('Color','w','Position',[100 100 900 500]);
plot(y3.Time, y3.Data, 'LineWidth', 2);

grid on;
box on;

xlabel('Tiempo (s)','FontSize',12);
ylabel('Temperatura (°C)','FontSize',12);
title('Respuesta de la planta térmica con histéresis ±1 °C','FontSize',13);

set(gca,'FontSize',11,'LineWidth',1);

exportgraphics(gcf,'respuesta_histeresis_1.pdf','ContentType','vector');