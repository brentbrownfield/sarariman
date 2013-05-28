/*
 * Copyright (C) 2013 StackFrame, LLC
 * This code is licensed under GPLv2.
 */
package com.stackframe.sarariman.xmpp;

import com.stackframe.sarariman.Authenticator;
import com.stackframe.sarariman.AuthenticatorImpl;
import com.stackframe.sarariman.Directory;
import com.stackframe.sarariman.Employee;
import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import org.apache.log4j.ConsoleAppender;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;
import org.apache.vysper.mina.TCPEndpoint;
import org.apache.vysper.storage.OpenStorageProviderRegistry;
import org.apache.vysper.storage.StorageProviderRegistry;
import org.apache.vysper.xmpp.addressing.Entity;
import org.apache.vysper.xmpp.addressing.EntityImpl;
import org.apache.vysper.xmpp.authorization.UserAuthorization;
import org.apache.vysper.xmpp.modules.roster.AskSubscriptionType;
import org.apache.vysper.xmpp.modules.roster.Roster;
import org.apache.vysper.xmpp.modules.roster.RosterException;
import org.apache.vysper.xmpp.modules.roster.RosterGroup;
import org.apache.vysper.xmpp.modules.roster.RosterItem;
import org.apache.vysper.xmpp.modules.roster.SubscriptionType;
import org.apache.vysper.xmpp.modules.roster.persistence.RosterManager;
import org.apache.vysper.xmpp.stanza.PresenceStanza;
import org.apache.vysper.xmpp.stanza.PresenceStanzaType;
import org.apache.vysper.xmpp.state.presence.LatestPresenceCache;

/**
 *
 * @author mcculley
 */
public class XMPPServerImpl implements XMPPServer {

    private final org.apache.vysper.xmpp.server.XMPPServer xmpp = new org.apache.vysper.xmpp.server.XMPPServer("stackframe.com");

    private final Directory directory;

    private final File keyStore;

    private final String keyStorePassword;

    public XMPPServerImpl(Directory directory, File keyStore, String keyStorePassword) {
        this.directory = directory;
        this.keyStore = keyStore;
        this.keyStorePassword = keyStorePassword;
    }

    private static Entity entity(Employee employee) {
        return new EntityImpl(employee.getUserName(), "stackframe.com", null);
    }

    public void start() throws Exception {
        ConsoleAppender consoleAppender = new ConsoleAppender(new PatternLayout());
        Logger.getRootLogger().addAppender(consoleAppender);
        final Authenticator authenticator = new AuthenticatorImpl(directory);
        StorageProviderRegistry providerRegistry = new OpenStorageProviderRegistry() {
            {
                add(new UserAuthorization() {
                    public boolean verifyCredentials(Entity entity, String passwordCleartext, Object credentials) {
                        System.err.println("in verifyCredentials with Entity. entity=" + entity);
                        return authenticator.checkCredentials(entity.getNode(), passwordCleartext);
                    }

                    public boolean verifyCredentials(String username, String passwordCleartext, Object credentials) {
                        System.err.println("in verifyCredentials with username. username=" + username);
                        return authenticator.checkCredentials(username, passwordCleartext);
                    }

                });
                add(new RosterManager() {
                    private final List<RosterGroup> groups = new ArrayList<RosterGroup>();

                    {
                        RosterGroup staff = new RosterGroup("staff");
                        groups.add(staff);
                    }

                    public Roster retrieve(final Entity entity) throws RosterException {
                        return new Roster() {
                            public Iterator<RosterItem> iterator() {
                                Collection<RosterItem> items = new ArrayList<RosterItem>();
                                for (Employee employee : directory.getEmployees()) {
                                    if (!employee.isActive()) {
                                        continue;
                                    }

                                    if (employee.getUserName().equals(entity.getNode())) {
                                        continue;
                                    }

                                    RosterItem ri = new RosterItem(entity(employee), employee.getDisplayName(), SubscriptionType.BOTH,
                                                                   AskSubscriptionType.ASK_SUBSCRIBED, groups);
                                    items.add(ri);
                                }

                                items = Collections.unmodifiableCollection(items);
                                return items.iterator();
                            }

                            public RosterItem getEntry(Entity entryEntity) {
                                Employee employee = directory.getByUserName().get(entryEntity.getNode());
                                return new RosterItem(entity(employee), employee.getDisplayName(), SubscriptionType.BOTH,
                                                      AskSubscriptionType.ASK_SUBSCRIBED, groups);
                            }

                        };
                    }

                    public void addContact(Entity entity, RosterItem ri) throws RosterException {
                    }

                    public RosterItem getContact(Entity entity, Entity e1) throws RosterException {
                        Employee employee = directory.getByUserName().get(e1.getNode());
                        return new RosterItem(entity(employee), employee.getDisplayName(), SubscriptionType.BOTH, AskSubscriptionType.ASK_SUBSCRIBED, groups);
                    }

                    public void removeContact(Entity entity, Entity entity1) throws RosterException {
                    }

                });
                add("org.apache.vysper.xmpp.modules.extension.xep0060_pubsub.storageprovider.LeafNodeInMemoryStorageProvider");
                add("org.apache.vysper.xmpp.modules.extension.xep0060_pubsub.storageprovider.CollectionNodeInMemoryStorageProvider");
            }

        };
        xmpp.addEndpoint(new TCPEndpoint());
        xmpp.setStorageProviderRegistry(providerRegistry);
        xmpp.setTLSCertificateInfo(keyStore, keyStorePassword);
        xmpp.start();
    }

    public void stop() throws Exception {
        xmpp.stop();
    }

    private static PresenceType type(PresenceStanza stanza) {
        if (PresenceStanzaType.isAvailable(stanza.getPresenceType())) {
            return PresenceType.available;
        } else {
            return PresenceType.unavailable;
        }
    }

    public Presence getPresence(String username) {
        String bareUserName = username.substring(0, username.indexOf('@'));
        Employee employee = directory.getByUserName().get(bareUserName);
        LatestPresenceCache presenceCache = xmpp.getServerRuntimeContext().getPresenceCache();
        PresenceStanza presence = presenceCache.getForBareJID(entity(employee));
        if (presence == null) {
            return new Presence(PresenceType.unavailable, null);
        } else {
            try {
                Presence p = new Presence(type(presence), presence.getStatus(null));
                return p;
            } catch (Exception e) {
                System.err.println("exception getting presence status. e=" + e);
                e.printStackTrace();
                return new Presence(PresenceType.unavailable, null);
            }
        }
    }

}
