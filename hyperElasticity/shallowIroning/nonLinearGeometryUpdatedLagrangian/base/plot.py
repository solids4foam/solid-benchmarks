import numpy as np
import matplotlib.pyplot as plt

# Load results from the literature
yastrebov_data = np.loadtxt('../../data/yastrebov.dat')
fischerWriggers_V = np.loadtxt('../../data/fischerWriggersVertical.dat')
fischerWriggers_H = np.loadtxt('../../data/fischerWriggersHorizontal.dat')
hartmannOliver_V = np.loadtxt('../../data/hartmannOliverVertical.dat')
hartmannOliver_H = np.loadtxt('../../data/hartmannOliverHorizontal.dat')
aster_V = np.loadtxt('../../data/asterVertical.dat')
aster_H = np.loadtxt('../../data/asterHorizontal.dat')
pouliosRenard_V = np.loadtxt('../../data/pouliosRenardVertical.dat')
pouliosRenard_H = np.loadtxt('../../data/pouliosRenardHorizontal.dat')

# Load case results
solids4foam = np.loadtxt('postProcessing/0/solidForcesdisplacement.dat')

# Scale time to fit to the time range from 1 to 2
for i in range(len(solids4foam[:,0])):
    time = solids4foam[i,0]
    if(time > 1):
        solids4foam[i,0] = (time -1)/5.0 + 1.0

fig=plt.figure(figsize=(12,7))

plt.rc('text', usetex=True)
plt.rc('font', family='serif')
plt.rc('xtick',labelsize=12)
plt.rc('ytick',labelsize=12)

plt.plot(solids4foam[:,0], solids4foam[:,1], color='black',linestyle='solid',linewidth=2,label='\\texttt{solids4foam: nonLinearGeometryUpdatedLagrangian-fe41}')
plt.plot(solids4foam[:,0], (-solids4foam[:,2]), color='black',linestyle='solid',linewidth=2)

plt.plot(yastrebov_data[:,0], (100*yastrebov_data[:,1]), linewidth=1, color='yellow', label='V. Yastrebov')
plt.plot(yastrebov_data[:,0], (-100*yastrebov_data[:,2]), linewidth=1, color='yellow')

plt.plot(aster_H[:,0], (100*aster_H[:,1]), linewidth=1, color='red', label='Code_Aster')
plt.plot(aster_V[:,0], (100*aster_V[:,1]), linewidth=1, color='red')

plt.plot(hartmannOliver_H[:,0], (100*hartmannOliver_H[:,1]), linewidth=1, color='blue', label='S. Hartmann et al.')
plt.plot(hartmannOliver_V[:,0], (100*hartmannOliver_V[:,1]), linewidth=1, color='blue')

plt.plot(fischerWriggers_H[:,0], (100*fischerWriggers_H[:,1]), linewidth=1, color='green', label='K. A. Fischer and P. Wriggers')
plt.plot(fischerWriggers_V[:,0], (100*fischerWriggers_V[:,1]), linewidth=1, color='green')

plt.plot(pouliosRenard_H[:,0], (100*pouliosRenard_H[:,1]), linewidth=1, color='cyan', label='K. Poulios and Y. Renard')
plt.plot(pouliosRenard_V[:,0], (100*pouliosRenard_V[:,1]), linewidth=1, color='cyan')
plt.title('Reaction forces at rounded block top surface')

plt.xlabel('Time $s$',fontsize=12)
plt.ylabel('Reaction forces',fontsize=12)
plt.legend(shadow=False,fontsize=12)
plt.xlim(0, 2)
plt.ylim(0, 450)
plt.grid()

figure = plt.gcf()
plt.tight_layout()
figure.savefig("reactionForces.png", dpi=300)
plt.close(fig)

